# DesktopPicker 배포 환경 크래시

## 🚨 문제 상황
**배포 환경에서 로비 미들웨어 초기화 전 DesktopPicker 컴포넌트가 마운트되면서 `getDesktopSharingFrameRate()` 호출 시 undefined 참조 오류 발생**

### 발생 환경
- 영향 파일: `features/desktop-picker/DesktopPicker.tsx`, `DesktopPickerPane.tsx`, `functions.ts`
- 증상: 배포 환경에서만 화면 공유 버튼 클릭 시 크래시 (로컬에서는 미발생)

### 기존 코드 문제점
```typescript
// functions.ts - null 체크 없이 설정값 접근
export function getDesktopSharingFrameRate(state: IReduxState) {
    return state['features/base/config'].desktopSharingFrameRate; // undefined 가능
}

// DesktopPickerPane.tsx - null 체크 없이 바로 사용
const frameRate = getDesktopSharingFrameRate(state); // undefined
const fps = frameRate.max; // TypeError: Cannot read properties of undefined
```

## 🔍 원인 분석

1. **배포 환경 타이밍 차이**: 로컬과 달리 배포 환경은 JS 번들 크기가 커서 초기화 순서가 달라짐
2. **config 미로드**: 로비 미들웨어 초기화 전 config가 Redux에 올라오기 전에 DesktopPicker가 마운트
3. **null 가드 부재**: `desktopSharingFrameRate`가 `undefined`일 때 방어 코드 없음

## ✅ 해결 방법

### 핵심 아이디어
**`functions.ts`에 null 가드 추가, `DesktopPickerPane`에 조건부 렌더링 추가**

### 구현 코드
```typescript
// functions.ts — null 가드 추가
export function getDesktopSharingFrameRate(state: IReduxState) {
    return state['features/base/config']?.desktopSharingFrameRate ?? null;
}

// DesktopPickerPane.tsx — undefined 체크 후 렌더링
const frameRate = getDesktopSharingFrameRate(state);
const fps = frameRate?.max ?? 30; // undefined면 기본값 30fps 사용

// DesktopPicker.tsx — 마운트 조건 추가
if (!isDesktopSharingEnabled) {
    return null; // 화면공유 비활성화 시 렌더링 스킵
}
```

## 📊 적용 결과
- 배포 환경 화면 공유 버튼 크래시 해소
- 기본값 30fps로 설정 미로드 시에도 정상 동작
- 4개 파일 수정으로 최소 변경

## 🎯 검증 방법
1. 배포 서버에서 화면 공유 버튼 클릭
2. DesktopPicker 팝업 정상 열림 확인
3. 콘솔 에러 없음 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-26/Strophe XMPP 에러 억제]]

---
**해결 완료**: 2026-05-26 | **적용**: desktop-picker 3개 파일 | **기법**: null 가드 + 기본값 fallback
