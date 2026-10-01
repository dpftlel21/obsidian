# Jitsi beforeunload 차단 패턴

## 🚨 문제 상황
**Jitsi 내부 코드가 `window.addEventListener('beforeunload', ...)` 등록 시 브라우저 Permissions-Policy 위반 경고 발생. KD는 beforeunload를 직접 등록해야 하는데 Jitsi가 이를 가로막음**

### 발생 환경
- 영향 파일: `kd_features/lobby/middleware.ts` (상단 즉시실행 블록)
- 증상: 콘솔에 `Permissions-Policy: beforeunload` 관련 경고, KD beforeunload 리스너 미등록

### 기존 상태
```
[Warning] Permissions Policy violation: beforeunload is not allowed in this document.
[Warning] Feature 'unload' is not available on insecure origins.
```

### 기존 코드 문제점
```typescript
// Jitsi 내부에서 등록한 beforeunload가 정책 위반 경고 유발
// KD도 같은 방식으로 등록하면 동일 문제 발생
window.addEventListener('beforeunload', handler); // 정책 위반
window.addEventListener('unload', handler);       // 정책 위반
```

## 🔍 원인 분석

1. **브라우저 정책 강화**: 최신 브라우저는 `beforeunload`/`unload` 이벤트 사용을 제한 (BFCache 최적화 방해)
2. **Jitsi 레거시 코드**: Jitsi 내부에서 `unload`/`beforeunload` 등록 → 정책 위반 경고
3. **KD 요구사항 충돌**: KD는 beforeunload에서 leave API를 호출해야 하는데 Jitsi가 오염시킴

## ✅ 해결 방법

### 핵심 아이디어
**`window.addEventListener`를 오버라이드해 Jitsi 내부의 `unload`/`beforeunload` 등록을 차단하고, KD 전용 리스너는 원본 `addEventListener`(`nativeAddEventListener`)로 등록**

### 구현 코드
```typescript
// 원본 addEventListener 보존 (KD 전용 리스너 등록용)
const nativeAddEventListener = window.addEventListener.bind(window);
const nativeRemoveEventListener = window.removeEventListener.bind(window);

// window.addEventListener 오버라이드
const originalAddEventListener = window.addEventListener;
window.addEventListener = function(type: string, listener: any, options?: any) {
    if (type === 'unload' || type === 'beforeunload') {
        // Jitsi 내부 등록 차단 (정책 위반 방지)
        return;
    }
    return originalAddEventListener.call(window, type, listener, options);
};

// KD 전용 에러 핸들러는 원본으로 등록 (차단 제외)
nativeAddEventListener('error', kdErrorHandler, true);
nativeAddEventListener('unhandledrejection', kdRejectionHandler);

// KD beforeunload는 원본으로 등록
nativeAddEventListener('beforeunload', () => {
    // leave API 호출 로직 (sessionStorage 기반)
    _saveActiveRoom();
});
```

### 오버라이드 적용 범위
```
window.addEventListener 호출
        │
        ├─ type === 'unload' → 차단 (Jitsi 내부)
        ├─ type === 'beforeunload' → 차단 (Jitsi 내부)
        └─ 그 외 → 원본 addEventListener로 전달

nativeAddEventListener 호출 (KD 전용)
        │
        └─ 차단 없이 직접 등록 (KD 리스너만)
```

## 📊 적용 결과
- Permissions-Policy 위반 경고 제거
- Jitsi 내부 unload/beforeunload 등록 차단
- KD 전용 리스너는 정상 동작

## 🎯 검증 방법
1. 회의실 입장 후 브라우저 콘솔 확인 → Permissions-Policy 경고 없음
2. 회의 퇴장 시 KD leave API 정상 호출 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-06-02/브라우저 강제종료 leave API 호출]]
- [[트러블슈팅/2026-05-26/Strophe XMPP 에러 억제]]

---
**해결 완료**: 2026-06-02 | **적용**: kd_features/lobby/middleware.ts | **기법**: window.addEventListener 오버라이드 + 원본 참조 보존
