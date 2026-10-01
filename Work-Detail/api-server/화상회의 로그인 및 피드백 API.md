# 화상회의 로그인 및 피드백 API

## 개요
화상회의 사용자 인증(로그인)과 회의 종료 후 피드백(feedback) 수집 API를 개발한 작업이다. 인증은 `app/api/auth`, 피드백은 `app/api/meeting`의 별도 라우터/서비스로 구성했다.

## 주요 변경/구현
- **화상회의 로그인 기능** (`ecc246d`): `app/api/auth/router.py`·`service.py`에 화상회의용 로그인 흐름을 추가(service.py +61 규모).
- **피드백 API** (`bfdaf16`): `feedback_router.py`(+141)·`feedback_service.py`(+219)를 신설하고 `models.py`(+65)·`schemas.py`(+106)에 피드백 엔터티/스키마를 정의, `app/main.py`에 라우터를 등록했다. DB 측은 `db_scripts/create_feedback_tables.sql`로 관리한다.

## 관련 커밋
- `2026-07-31` `bfdaf16` 피드백 api 개발
- `2026-07-22` `ecc246d` 화상회의 로그인 기능 개발
