# 코스 추천 및 geometry v3

## 개요
코스 추천·생성 로직을 고도화했다. 축제를 필수로 포함하는 코스 추천, 출발지 좌표 검증, geometry v3 반영과 함께 회귀 테스트를 대거 보강해 추천 조건의 정합성을 확보했다.

## 주요 구현·변경
- 코스/장소/취향 API 구성: `src/api/courses/`, `src/api/places/`, `src/api/preferences/` 도입 및 각 화면(BrowseView, CourseDetailView, CourseResultView, CourseEditSheet) 연동.
- 축제 필수 포함 코스 추천: `course-result/requiredFestival.ts` 신설, 출발지 좌표 검증(`DeparturePlacePicker`), `courses/errors.ts` 오류 타입 추가.
- geometry v3: `api/route/geometry.ts` 개편, `geometry.test.ts`·`requiredFestival.test.ts`·`useCourseResult.test.tsx`·`FestivalDetailView.test.tsx` 등 회귀 테스트 보강.

## 주요 구현·변경 근거
- `dfed4d7`: `requiredFestival.ts`(+100), `courses/errors.ts`(+53), 테스트 파일 다수 추가.
- `38073aa`: `geometry.test.ts`(+188), `errors.test.ts`(+109), `requiredFestival.test.ts`(+174) 등 테스트 중심 변경.

## 관련 커밋
- `2026-07-26` `167e5e2` 각 페이지 ui 개선 및 api 기능 구현
- `2026-09-02` `dfed4d7` 축제 필수 포함 코스 추천과 출발지 좌표 검증 반영
- `2026-09-02` `38073aa` geometry v3 반영과 축제 필수 포함·추천 조건 회귀 테스트 보강

관련: [[동선 계산 및 최적화 경로 지도 표시]], [[스마트 플래너]], [[현재 위치 기준 코스 재계산]]
