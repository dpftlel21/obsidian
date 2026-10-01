# 지도 재검색 시 이전 영역 결과 노출과 취향 payload 역전

## 배경
심사 대응 중 발견된 긴급 결함(P0·P1) 정리 작업(`0b539bc`, 2026-09-20)의 일부. 백엔드 긴급 수정 인계서에 근거해 **최소 범위**로 4건을 수정했으며, 이 문서는 그중 지도 검색·취향 저장과 직접 관련된 결함을 다룬다. (스마트플래너 16개 구·군 제공은 [[스마트 플래너]] 참고.)

---

## 결함 1 (P0) — 지도 재검색 시 이전 영역 결과가 placeholder로 노출

### 증상
지도 영역을 옮겨 다시 검색하면, 새 영역의 결과가 도착하기 전 **이전 영역의 장소들이 그대로 화면에 남아** 있었다. 사용자는 엉뚱한 지역 결과를 잠깐 실제 결과로 오인하게 된다.

### 재현 경로
1. A 영역에서 키워드 검색 → 결과 표시
2. 지도를 B 영역으로 이동 후 재검색 (검색 서명 변경)
3. B 응답 도착 전, A 결과가 placeholder로 노출됨

### 원인
`useTourismSearchState.ts`의 `visibleKeywordPlaces` 계산에서, 검색 서명이 바뀐 로딩 구간에도 React Query의 `isPlaceholderData`(직전 쿼리 데이터)를 근거로 누적 결과를 노출하고 있었다. 즉 **서명 불일치 상태에서 `|| keywordPlaceQuery.isPlaceholderData` 조건이 이전 영역 데이터를 통과**시켰다.

```ts
// Before
const visibleKeywordPlaces =
  page === 0 && !keywordPlaceQuery.isPlaceholderData && keywordPlaceQuery.data?.page === 0
    ? keywordPlaceQuery.data.places
    : accumulatedPlaces.signature === searchSignature || keywordPlaceQuery.isPlaceholderData
      ? accumulatedPlaces.places
      : undefined;
```

### 해결
`|| keywordPlaceQuery.isPlaceholderData`를 제거해, **현재 검색 서명과 일치하는 누적 결과만** 표시하도록 했다. 새 검색 로딩 중에는 `undefined`(빈 결과·개수 0)가 되어 이전 영역이 남지 않는다. 첫 페이지 실제 응답 우선, 같은 검색의 "더 보기" 병합은 유지된다.

```ts
// After
    : accumulatedPlaces.signature === searchSignature
      ? accumulatedPlaces.places
      : undefined;
```

- 파일: `src/components/search/useTourismSearchState.ts` (`visibleKeywordPlaces`, ~234행)

---

## 결함 2 (P1) — 취향 저장 직후 다음 payload 역전

### 증상
취향을 저장한 뒤 곧바로 다른 항목을 바꾸면, 방금 저장한 값이 **이전(저장 전) 값으로 되돌아간** 요청이 서버로 나갔다.

### 원인
`useUpdateMyPreferencesMutation`의 `onSuccess`에서 `invalidateQueries`만 호출하고 있었다. 무효화 후 **refetch가 끝나기 전에** 사용자가 다음 조작을 하면, 다음 payload가 아직 갱신되지 않은(저장 전) 캐시로 구성되어 저장값이 역전됐다.

### 해결
무효화 **이전에** 서버 응답을 캐시에 직접 반영(`setQueryData`)해, refetch 완료 전에도 다음 payload가 최신 저장값을 사용하도록 했다. 기존 옵션·외부 콜백·오류 처리는 보존.

```ts
onSuccess: (data, variables, onMutateResult, context) => {
  // refetch 완료 전 다음 조작이 이전 캐시로 payload를 만들지 않도록 서버 응답을 먼저 캐시에 반영한다.
  queryClient.setQueryData(preferencesQueryKeys.mine(), data);
  queryClient.invalidateQueries({ queryKey: preferencesQueryKeys.mine() });
  options?.onSuccess?.(data, variables, onMutateResult, context);
},
```

- 파일: `src/api/preferences/queries.ts` (`useUpdateMyPreferencesMutation`, ~25행)

---

## 결함 3 (P1, 동반 수정) — 홈 추천 카드 장소명·지역 fallback

상세 조회(localizedPlace)가 실패·미도착이어도 추천 API가 준 실제 장소명/지역을 표시하도록 fallback을 보강했다. 상세 성공 시 다국어 우선순위·비한국어 fallback 순서는 보존.

```tsx
const placeName =
  locale === 'ko'
    ? localizedPlace?.nameKo || localizedPlace?.displayName || item.place.name || tx('추천 장소')
    : localizedPlace?.displayName || localizedPlace?.nameKo || item.place.name;
const district = localizedPlace?.district || item.place.district || '부산';
```

- 파일: `src/components/home/HomeView.tsx` (`RecommendationSection`, ~703행)

---

## 검증
- `tsc -b` 통과, `vite build` 성공, 변경 파일 lint 에러 없음.
- ⚠️ 실제 브라우저 재현(지도 재검색 지연·취향 연속 저장·홈 상세 실패)은 이 커밋 시점 **미검증**으로 기록됨.
- 회귀 테스트 시나리오(커밋 스펙 기준): `useTourismSearchState.mapArea.test.tsx`(A→B placeholder에서 빈 결과→실제 결과, 같은 검색 더 보기 보존), `preferences/queries.test.tsx`(성공 응답이 refetch 완료 전 캐시 반영).

## 영향 범위
- 검색 결과 표시 로직, 취향 저장 후 요청 직렬화, 홈 추천 카드 표기. 추천 요청 계약·페이징 병합 동작은 변경 없음.

## 관련 커밋
- `2026-09-20` `0b539bc` 긴급 결함 4건과 스마트플래너 취향 초기값·로그인 장식 아이콘 정리
  - 근거 문서: `docs/claude-frontend-urgent-fix-spec-2026-09-20.md`

## 관련 노트
- [[스마트 플래너]]
- [[관광 데이터 조회 및 장소 검색]]
- [[백엔드 API 연동]]
- [[커밋 이력 - bld-frontend]]
