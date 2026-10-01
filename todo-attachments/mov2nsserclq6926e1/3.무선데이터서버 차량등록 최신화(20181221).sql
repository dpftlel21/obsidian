/* 무선데이터서버 차량등록 최신화
                updated: 2018.12.21 정철화 */

-- 무선데이터서버 최신화 (신규) 
  SELECT   C.DIV_IO DIV,
           REPLACE(PKG_MHS_CODE2.FNC_GET_1LVL_DEPTNM(A.DEPT_CD),'사업본부','') BON_NM,
           PKG_MHS_CODE2.FNC_GET_2LVL_DEPTNM(A.DEPT_CD) JISA_NM,
           PKG_MHS_CODE2.FNC_GET_3LVL_DEPTNM(A.DEPT_CD) DEPT_NM,
--           A.DEPT_CD,
--           PKG_MFS_CODE.FNC_GET_CORP_NM (A.COMP_REG_NO) CORP_NM,
--           SUBSTR (B.DT_S_CAR_REG, 0, 4) CAR_YEAR,
--           COUNT ( * ) CNT,
           PKG_TUS_CODE.FNC_GET_NMLINE_USECDLINE(A.CD_LINE) NM_LINE,
           PKG_SMS_CODE.FNC_GET_CORPCD_USENOCAR(A.NO_CAR) CORP_CD,
--           A.CD_LINE,
           A.NO_CAR,
--           A.VIN,
           '0',
           CASE WHEN C.DIV_IO = 'I' THEN '11'       -- 시내는 11
                  WHEN C.DIV_IO = 'O' THEN '14'     -- 시외는 14
           END  AS DIV,
           'L181221_0' || DENSE_RANK() OVER (PARTITION BY  A.DEPT_CD ORDER BY A.DEPT_CD) RN,    -- 앞에 숫자는 무선데이터 프로그램에서 노선을 만든 날짜로 변경한다.
           'Y'
    FROM   CAR_HIS A, CAR_MECH B, CM_DIV_SVC C
   WHERE   A.VIN = B.VIN
       AND A.DIV_SVC = C.DIV_SVC
       AND A.CD_STATUS_CAR IN ('C', 'D')
       AND '20241209' BETWEEN A.DT_S AND A.DT_E                             -- 데이터출력 기준이 되는 일자
       AND A.DIV_SVC NOT IN ('Q', 'Z')
       AND A.NO_CAR LIKE '%충남71아%'
--       AND PKG_MHS_CODE2.FNC_GET_3LVL_DEPTNM(A.DEPT_CD) = '공주(삼흥)'
--       AND PKG_TUS_CODE.FNC_GET_NMLINE_USECDLINE(A.CD_LINE) = '화성똑버스03'
--       AND A.COMP_REG_NO IN (SELECT   COMP_REG_NO
--                               FROM   D_COMPANY
--                              WHERE   CORP_CD = 'Y00' )
GROUP BY   C.DIV_IO,
           A.DEPT_CD,
           PKG_MFS_CODE.FNC_GET_CORP_NM (A.COMP_REG_NO),
           SUBSTR (B.DT_S_CAR_REG, 0, 4),
           A.CD_LINE,
           A.VIN,
           A.NO_CAR
ORDER BY NO_CAR




-- 무선데이터서버 최신화 (갱신)
SELECT      A.DIV_IO DIV,
              REPLACE(PKG_MHS_CODE2.FNC_GET_1LVL_DEPTNM(A.DEPT_CD),'사업본부','') BON_NM,
              PKG_MHS_CODE2.FNC_GET_2LVL_DEPTNM(A.DEPT_CD) JISA_NM,
              PKG_MHS_CODE2.FNC_GET_3LVL_DEPTNM(A.DEPT_CD) DEPT_NM,
        --      B.DEPT_CD,
              PKG_TUS_CODE.FNC_GET_NMLINE_USECDLINE(A.CD_LINE) NM_LINE,
              PKG_SMS_CODE.FNC_GET_CORPCD_USENOCAR(A.NO_CAR) CORP_CD,              
              A.CAR_YEAR,
              A.NO_CAR 차량번호,
              '0' 차대번호,
              CASE  WHEN A.DIV_IO = 'I' THEN '11'       -- 시내는 11
                      WHEN A.DIV_IO = 'O' THEN '14'     -- 시외는 14
              END  AS 차량유형,
              A.RN 노선코드,
              'Y' WIFI수신여부,
              B.NO_CAR,
              B.RN
FROM
            (SELECT     A.DEPT_CD,
                          PKG_SMS_CODE.FNC_GET_CORPCD_USENOCAR(A.NO_CAR) CORP_CD,
                          A.NO_CAR,
                          B.CAR_YEAR,
                          'L181221_0' || DENSE_RANK() OVER (PARTITION BY  A.DEPT_CD ORDER BY A.DEPT_CD) RN,    -- 앞에 숫자는 무선데이터 프로그램에서 노선을 만든 날짜로 변경한다.
                          C.DIV_IO DIV_IO,
                          A.CD_LINE                          
            FROM       CAR_HIS A, CAR_MECH B, CM_DIV_SVC C
            WHERE     A.VIN = B.VIN
            AND        A.DIV_SVC = C.DIV_SVC
            AND        A.CD_STATUS_CAR IN ('C', 'D')
            AND        '20251112' BETWEEN A.DT_S AND A.DT_E                             -- 데이터출력 기준이 되는 일자 (최근일자를 쓴다.)
            AND        A.DIV_SVC NOT IN ('Q', 'Z')) A,
            (SELECT      A.DEPT_CD,
                          PKG_SMS_CODE.FNC_GET_CORPCD_USENOCAR(A.NO_CAR) CORP_CD,
                          A.NO_CAR,
                          'L181221_0' || DENSE_RANK() OVER (PARTITION BY  A.DEPT_CD ORDER BY A.DEPT_CD) RN    -- 앞에 숫자는 무선데이터 프로그램에서 노선을 만든 날짜로 변경한다.
            FROM       CAR_HIS A, CAR_MECH B, CM_DIV_SVC C
            WHERE     A.VIN = B.VIN
            AND        A.DIV_SVC = C.DIV_SVC
            AND        A.CD_STATUS_CAR IN ('C', 'D')
            AND        '20251112' BETWEEN A.DT_S AND A.DT_E                             -- 데이터출력 기준이 되는 일자 (예전일자를 쓴다.)
            AND        A.DIV_SVC NOT IN ('Q', 'Z')) B
WHERE    A.NO_CAR = B.NO_CAR(+)
AND       A.CORP_CD = B.CORP_CD(+)
ORDER BY RN

AND PKG_MHS_CODE2.FNC_GET_3LVL_DEPTNM(A.DEPT_CD) LIKE '%수원%' 

--ORDER BY  NM_LINE ASC
--AND       B.RN IS NULL
--ORDER BY BON_NM, JISA_NM, DEPT_NM, NM_LINE, A.NO_CAR

-- ★ 





-- 무선데이터서버 최신화 (갱신)
SELECT       A.NO_CAR 차량번호,
              '0' 차대번호,
              CASE  WHEN A.DIV_IO = 'I' THEN '11'       -- 시내는 11
                      WHEN A.DIV_IO = 'O' THEN '14'     -- 시외는 14
              END  AS 차량유형,
              A.RN 노선코드,
              'Y' WIFI수신여부
FROM
            (SELECT     A.DEPT_CD,
                          PKG_SMS_CODE.FNC_GET_CORPCD_USENOCAR(A.NO_CAR) CORP_CD,
                          A.NO_CAR,
                          B.CAR_YEAR,
                          'L181221_0' || DENSE_RANK() OVER (PARTITION BY  A.DEPT_CD ORDER BY A.DEPT_CD) RN,    -- 앞에 숫자는 무선데이터 프로그램에서 노선을 만든 날짜로 변경한다.
                          C.DIV_IO DIV_IO,
                          A.CD_LINE                          
            FROM       CAR_HIS A, CAR_MECH B, CM_DIV_SVC C
            WHERE     A.VIN = B.VIN
            AND        A.DIV_SVC = C.DIV_SVC
            AND        A.CD_STATUS_CAR IN ('C', 'D')
            AND        '20260109' BETWEEN A.DT_S AND A.DT_E                             -- 데이터출력 기준이 되는 일자 (최근일자를 쓴다.)
            AND        A.DIV_SVC NOT IN ('Q', 'Z')) A,
            (SELECT      A.DEPT_CD,
                          PKG_SMS_CODE.FNC_GET_CORPCD_USENOCAR(A.NO_CAR) CORP_CD,
                          A.NO_CAR,
                          'L181221_0' || DENSE_RANK() OVER (PARTITION BY  A.DEPT_CD ORDER BY A.DEPT_CD) RN    -- 앞에 숫자는 무선데이터 프로그램에서 노선을 만든 날짜로 변경한다.
            FROM       CAR_HIS A, CAR_MECH B, CM_DIV_SVC C
            WHERE     A.VIN = B.VIN
            AND        A.DIV_SVC = C.DIV_SVC
            AND        A.CD_STATUS_CAR IN ('C', 'D')
            AND        '20260109' BETWEEN A.DT_S AND A.DT_E                             -- 데이터출력 기준이 되는 일자 (예전일자를 쓴다.)
            AND        A.DIV_SVC NOT IN ('Q', 'Z')) B
WHERE    A.NO_CAR = B.NO_CAR(+)
AND       A.CORP_CD = B.CORP_CD(+)

