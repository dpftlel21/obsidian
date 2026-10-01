import oracledb
import pymysql
from datetime import datetime, timedelta
import logging
import os

def setup_logger():
    logger = logging.getLogger('FoodDataSync')
    logger.setLevel(logging.INFO)
    
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    
    log_dir = 'C:\\Users\\user\\Desktop\\LEEKYUDONG\\2.제작\\KD - ERP\\식사등록\\logs'
    if not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)
        print(f"로그 디렉토리를 생성했습니다: {log_dir}")
    
    file_handler = logging.FileHandler(os.path.join(log_dir, 'food_data_sync.log'))
    file_handler.setLevel(logging.INFO)
    
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    console_handler.setFormatter(formatter)
    file_handler.setFormatter(formatter)
    
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    
    return logger

logger = setup_logger()

# Oracle thick mode 초기화 (전역 1회)
try:
    oracledb.init_oracle_client(lib_dir=r"D:\oracle\instantclient_21_10")
    logger.info("Oracle 클라이언트 초기화 성공 (thick mode)")
except Exception as e:
    logger.error(f"Oracle 클라이언트 초기화 실패: {e}")
    raise SystemExit("Oracle Instant Client 초기화 실패. 프로그램을 종료합니다.")

def get_days_input():
    while True:
        try:
            days = int(input("몇 일 전까지의 데이터를 처리하시겠습니까? (숫자만 입력): "))
            if days <= 0:
                print("1 이상의 숫자를 입력해주세요.")
                continue
            return days
        except ValueError:
            print("올바른 숫자를 입력해주세요.")

def sync_food_data_to_erp(days_back):
    logger.info(f"TB_FOOD 데이터 MariaDB -> Oracle 동기화 시작 ({days_back}일 전부터)")
    
    today = datetime.now()
    target_date = today - timedelta(days=days_back)
    
    today_str = today.strftime('%Y%m%d')
    target_date_str = target_date.strftime('%Y%m%d')
    
    logger.info(f"처리 대상 날짜 범위: {target_date_str} ~ {today_str} ({days_back}일전 ~ 오늘)")
    
    try:
        maria_con = pymysql.connect(host='211.200.31.38', port=3306, user='buspia_user', 
                                    password='qjtmvldk!2016', database='buspia_db', 
                                    connect_timeout=10)
        maria_cur = maria_con.cursor(pymysql.cursors.DictCursor)
        
        ora_con = oracledb.connect(user="KDUSER", password="KDUSER", host="221.146.5.13", 
                                   port=1521, service_name="KDIIS")
        ora_cur = ora_con.cursor()
        
        process_food_data(maria_cur, ora_cur, ora_con, target_date_str, today_str)
        
        return True
    
    except Exception as e:
        logger.error(f"동기화 중 오류 발생: {e}")
        if 'ora_con' in locals():
            ora_con.rollback()
        return False
    
    finally:
        if 'maria_cur' in locals() and maria_cur:
            maria_cur.close()
        if 'maria_con' in locals() and maria_con:
            maria_con.close()
        if 'ora_cur' in locals() and ora_cur:
            ora_cur.close()
        if 'ora_con' in locals() and ora_con:
            ora_con.close()

def process_food_data(maria_cur, ora_cur, ora_con, start_date, end_date):
    logger.info("TB_FOOD 테이블 구조 확인 중...")
    maria_cur.execute("SHOW COLUMNS FROM TB_FOOD")
    columns_info = maria_cur.fetchall()
    
    available_columns = [col['Field'] for col in columns_info]
    logger.info(f"TB_FOOD 테이블의 컬럼들: {available_columns}")
    
    required_columns = ['USE_DT', 'FOOD_TYP', 'EMP_NO', 'DEPT_CD', 'FOOD_DEPT_CD', 'FOOD_DEPT_NM', 
                       'FOOD_PEOPLE', 'CH_YN', 'CH_DT', 'DEL_YN', 'DEL_GB', 'DEL_ID', 'DT_REG', 
                       'ID_REG', 'DT_UPT', 'ID_UPT', 'ERP_YN', 'ERP_DT']
    
    existing_columns = [col for col in required_columns if col in available_columns]
    missing_columns = [col for col in required_columns if col not in available_columns]
    
    if missing_columns:
        logger.warning(f"TB_FOOD 테이블에 없는 컬럼들: {missing_columns}")
    
    logger.info(f"사용할 컬럼들: {existing_columns}")
    
    columns_str = ', '.join(existing_columns)
    select_food_query = f"""
    SELECT {columns_str}
    FROM TB_FOOD
    WHERE USE_DT >= %s AND USE_DT <= %s
    ORDER BY USE_DT, FOOD_TYP, EMP_NO
    """
    
    maria_cur.execute(select_food_query, (start_date, end_date))
    food_data = maria_cur.fetchall()
    logger.info(f"TB_FOOD 테이블에서 {len(food_data)}개 레코드 조회됨")
    
    inserted_rows = 0
    updated_rows = 0
    skipped_rows = 0
    
    for row in food_data:
        try:
            check_query = """
            SELECT COUNT(*) FROM A_FOOD 
            WHERE USE_DT = :use_dt AND FOOD_TYP = :food_typ AND EMP_NO = :emp_no
            """
            
            ora_cur.execute(check_query, {
                'use_dt': row['USE_DT'],
                'food_typ': row['FOOD_TYP'],
                'emp_no': row['EMP_NO']
            })
            
            exists = ora_cur.fetchone()[0] > 0
            
            if exists:
                update_parts = []
                update_params = {}
                
                for col in existing_columns:
                    if col not in ['USE_DT', 'FOOD_TYP', 'EMP_NO']:
                        update_parts.append(f"{col} = :{col.lower()}")
                        update_params[col.lower()] = row[col]
                
                update_params['use_dt'] = row['USE_DT']
                update_params['food_typ'] = row['FOOD_TYP'] 
                update_params['emp_no'] = row['EMP_NO']
                
                update_query = f"""
                UPDATE A_FOOD SET {', '.join(update_parts)}
                WHERE USE_DT = :use_dt AND FOOD_TYP = :food_typ AND EMP_NO = :emp_no
                """
                
                ora_cur.execute(update_query, update_params)
                updated_rows += 1
                logger.info(f"Oracle 업데이트 완료: {row['USE_DT']}, {row['FOOD_TYP']}, {row['EMP_NO']}")
                
            else:
                insert_columns = existing_columns
                insert_placeholders = [f":{col.lower()}" for col in insert_columns]
                insert_params = {col.lower(): row[col] for col in insert_columns}
                
                insert_query = f"""
                INSERT INTO A_FOOD ({', '.join(insert_columns)}) 
                VALUES ({', '.join(insert_placeholders)})
                """
                
                ora_cur.execute(insert_query, insert_params)
                inserted_rows += 1
                logger.info(f"Oracle 삽입 완료: {row['USE_DT']}, {row['FOOD_TYP']}, {row['EMP_NO']}")
            
        except Exception as e:
            logger.error(f"레코드 처리 오류: {row['USE_DT']}, {row['FOOD_TYP']}, {row['EMP_NO']} - {e}")
            skipped_rows += 1
    
    ora_con.commit()
    logger.info(f"Oracle 처리 완료 - 삽입: {inserted_rows}개, 업데이트: {updated_rows}개, 오류: {skipped_rows}개")

def main():
    start_time = datetime.now()
    logger.info("TB_FOOD 데이터 동기화 프로그램 시작")
    
    days_back = get_days_input()
    
    print(f"{days_back}일 전부터 오늘까지의 데이터를 처리합니다...")
    
    success = sync_food_data_to_erp(days_back)
    
    end_time = datetime.now()
    processing_time = end_time - start_time
    
    if success:
        logger.info(f"TB_FOOD 데이터 동기화 완료. 소요 시간: {processing_time}")
        print(f"동기화가 완료되었습니다. 소요 시간: {processing_time}")
    else:
        logger.error(f"TB_FOOD 데이터 동기화 실패. 소요 시간: {processing_time}")
        print(f"동기화가 실패했습니다. 로그를 확인해주세요. 소요 시간: {processing_time}")

if __name__ == "__main__":
    main()