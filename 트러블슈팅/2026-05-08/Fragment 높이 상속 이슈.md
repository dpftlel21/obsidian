
# Fragment 높이 상속 이슈

## 🚨 문제 상황
**BusinessRevenueTable에서 Card를 `h-full`로 변경했으나, 테이블이 여전히 높이를 제대로 받지 못함**

### 증상
- 페이지에서 wrapper에 JS로 정확한 높이를 설정했는데도 Card가 그 높이를 따르지 않음
- 다른 테이블들은 정상 동작하는데, BusinessRevenueTable만 문제 발생

## 🔍 원인 분석

### 문제의 구조
```tsx
// BusinessRevenueTable의 문제 구조
return (
  <>                              {/* ← Fragment: DOM 노드 없음 */}
    {isApproving && <LazySpinner />}   {/* ← Card와 형제 관계 */}
    <Card className="h-full">          {/* ← h-full이 Fragment 안에서 무의미 */}
      ...
    </Card>
  </>
)
```

### Fragment의 CSS 한계
1. **DOM 노드 부재**: Fragment(`<>`)는 DOM에 렌더링되지 않음
2. **CSS 부모 역할 불가**: React의 논리적 부모일 뿐 CSS 부모가 아님
3. **형제 요소 충돌**: Fragment 안에 `<LazySpinner />`와 `<Card>`가 형제로 존재
4. **높이 분배 문제**: `LazySpinner`가 공간을 차지하면서 Card의 높이 계산이 깨짐

### h-full의 동작 원리
```css
.h-full { height: 100%; }
```
- `height: 100%`는 **부모 요소의 높이 100%**를 의미
- Fragment는 CSS 부모가 아니므로 실제 부모 div까지 거슬러 올라감
- 하지만 Fragment 내 형제 요소들이 레이아웃 흐름을 방해

## ✅ 해결 방법

### Fragment 제거 및 구조 개선
```tsx
// Before: Fragment로 높이 상속 차단
return (
  <>
    {isApproving && <LazySpinner />}
    <Card className="h-full">...</Card>
  </>
)

// After: Card 내부로 조건부 렌더링 이동
return (
  <Card className="h-full flex flex-col">
    <CardContent className="p-2 flex-1 flex flex-col min-h-0">
      {isApproving && <LazySpinner />}  {/* ← Card 내부로 이동 */}
      {/* 테이블 내용 */}
    </CardContent>
  </Card>
)
```

### 변경 사항
1. **Fragment 제거**: `<>` 완전 제거
2. **LazySpinner 이동**: Card 외부 → Card 내부 CardContent로
3. **Flex 구조**: `flex flex-col`로 수직 레이아웃 명확화
4. **높이 상속**: Card가 부모 div의 직접 자식이 되어 `h-full` 정상 동작

## 🚫 예외 상황

### SeveranceStausTable의 경우
이 컴포넌트는 Card **바깥**에 모달들이 있어서 Fragment가 필요:

```tsx
return (
  <>
    <Card className="h-full flex flex-col">...</Card>
    <SignLineRegistration ... />      {/* fixed 포지션 모달 — Card 바깥 필요 */}
    <DraftEstimate ... />             {/* fixed 포지션 모달 */}
    <SeveranceStatusSlipPop ... />    {/* fixed 포지션 모달 */}
    <PopupComponent />
  </>
)
```

### 예외가 허용되는 이유
1. **레이아웃 분리**: Card만 유일한 블록 레벨 요소
2. **모달 특성**: 나머지 모달들은 `position: fixed`로 레이아웃 흐름에서 벗어남
3. **실질적 단일 자식**: Card가 사실상 부모 div의 유일한 레이아웃 자식
4. **h-full 정상**: Fragment 내에 레이아웃에 영향을 주는 형제가 없으므로 정상 동작

## 📋 해결 체크리스트

### Fragment 사용 시 확인사항
- [ ] Fragment 내에 Card와 같은 레벨의 다른 블록 요소가 있는가?
- [ ] 조건부 렌더링되는 요소가 Card와 형제 관계인가?
- [ ] 모든 형제 요소가 `position: fixed` 또는 `absolute`인가?
- [ ] Card에서 `h-full`이 예상대로 동작하는가?

### Fragment 제거 기준
**제거 필요한 경우:**
```tsx
// ❌ 문제: Card와 다른 블록 요소가 형제
<>
  {condition && <SomeComponent />}  // 블록 레벨 요소
  <Card className="h-full">...</Card>
</>
```

**제거 불필요한 경우:**
```tsx
// ✅ 괜찮음: 모달들은 fixed positioning
<>
  <Card className="h-full">...</Card>
  <Modal style={{position: 'fixed'}}>...</Modal>
  <Popup style={{position: 'fixed'}}>...</Popup>
</>
```

## 🛠 적용 결과

### 수정된 파일
- `widgets/business-revenue/BusinessRevenueTable.tsx`
  - Fragment 제거
  - LazySpinner를 CardContent 내부로 이동
  - Card 구조 최적화

### 검증
1. **높이 상속**: Card가 wrapper에서 계산된 높이를 정확히 받음
2. **조건부 렌더링**: LazySpinner가 Card 내부에서 정상 표시
3. **레이아웃 안정성**: 다른 테이블들과 동일한 높이 동작

## 💡 핵심 원칙

### React Fragment 사용 규칙
1. **단순 그룹핑**: 의미적 그룹핑을 위해서만 사용
2. **CSS 부모 회피**: 높이, 너비 같은 CSS 속성이 중요한 경우 피할 것
3. **형제 요소 주의**: 레이아웃에 영향을 주는 형제가 있으면 Fragment 재검토

### 높이 상속 디버깅
1. **부모 체크**: 실제 CSS 부모가 누구인지 확인
2. **형제 분석**: 같은 레벨의 다른 요소들이 공간을 차지하는지 확인
3. **DevTools**: React DevTools와 Elements 패널로 DOM 구조 비교

## 📚 관련 문서
- [[테이블 뷰포트 최적화]] - 전체 높이 최적화 프로젝트
- [[고정 컬럼 z-index 충돌]] - 다른 테이블 레이아웃 이슈

---

**해결 완료**: 2026-05-08 | **기법**: Fragment 제거 및 구조 개선 | **영향**: BusinessRevenueTable