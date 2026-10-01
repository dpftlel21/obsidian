# API 타임아웃 및 재시도 처리

## 배경
네트워크 지연 시 요청이 무한 대기하거나, 일시적 실패에 그대로 노출되거나, 반대로 회복 불가능한 오류를 불필요하게 재시도해 대기만 늘어나는 문제가 있었다. `aaa7d4a`(2026-09-13)에서 타임아웃·재시도 정책을 오류 성격별로 정리했다.

## 증상
- 백엔드가 응답 없이 멈추면 화면이 **스켈레톤 상태에서 영영 멈춤**.
- TourAPI 일일 조회 한도 소진처럼 **당일 회복 불가능한 오류**도 일반 5xx처럼 재시도되어 대기만 길어짐.
- 결정적 4xx 오류까지 무조건 1회 재시도.

## 원인
1. **무한 대기**: axios 기본 `timeout`은 0(무제한)이다. 백엔드가 응답 없이 멈추면 요청 Promise가 settle되지 않아 react-query의 `isPending`이 계속 true로 남고 스켈레톤이 풀리지 않는다.
2. **재시도 분별 부족**: `queryClient`가 오류 성격과 무관하게 `retry: 1`로 일괄 재시도했고, "회복 불가" 판별은 길찾기 공급사 쿼터(503)만 다뤄 TourAPI 일일 한도는 커버하지 못했다.

## 해결
### 1) 실제 타임아웃 강제 + 상향
```ts
// axios 기본 timeout은 0(무제한). 백엔드가 멈추면 Promise가 영영 settle되지 않아 스켈레톤에서 멈춘다.
const REQUEST_TIMEOUT_MS = 60000; // 15000 → 60000
```

### 2) 결정적 실패 판별 분리 (재시도 제외 대상 확장)
`isQuotaExhaustedError`(503 전용)를 두 판별로 분리하고, TourAPI 일일 한도는 **응답 본문 형태와 무관하게** 같은 결정적 실패로 취급한다.
```ts
function isTourApiDailySafeLimitError(error: unknown) {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;
    if (hasTourApiDailySafeLimitMessage(data)) return true;
    if (data && typeof data === 'object' && 'message' in data
        && hasTourApiDailySafeLimitMessage(data.message)) return true;
  }
  return error instanceof Error && hasTourApiDailySafeLimitMessage(error.message);
}
function isRouteProviderQuotaExhaustedError(error) { /* 503 PROVIDER_QUOTA_EXHAUSTED */ }
```
`isRetriableApiError`에서 두 오류를 모두 제외하고, TourAPI 한도는 사용자 안내 문구를 반환한다.
```ts
// "관광정보의 오늘 조회 한도에 도달했어요. 나중에 다시 확인해 주세요."
if (isTourApiDailySafeLimitError(error)) return TOUR_API_DAILY_SAFE_LIMIT_USER_MESSAGE;
```

### 3) react-query 재시도를 성격 기반으로
```ts
// Before: retry: 1  (모든 실패를 일괄 1회 재시도)
// After:  결정적 4xx·공급사 쿼터는 즉시 끝내고, 네트워크·일시적 서버 오류만 1회 재시도
retry: (failureCount, error) => failureCount < 1 && isRetriableApiError(error),
```

## 관련 파일
- `src/api/client.ts` — 타임아웃 상수, `isTourApiDailySafeLimitError`/`isRouteProviderQuotaExhaustedError`, `isRetriableApiError`
- `src/app/queryClient.ts` — `retry` 콜백을 `isRetriableApiError` 기반으로 전환

## 비고
같은 커밋에서 누락 번역 보강(`i18n/auto`)과 마이페이지 표면 개선을 동반했다.

## 관련 커밋
- `2026-09-13` `aaa7d4a` 누락 번역 보강 및 API 타임아웃·재시도·마이페이지 표면 개선

## 관련 노트
- [[백엔드 API 연동]]
- [[관광 데이터 조회 및 장소 검색]]
- [[커밋 이력 - bld-frontend]]
