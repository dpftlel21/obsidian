# Strophe·XMPP 에러 억제

## 🚨 문제 상황
**로비 모드 진입 시 Jitsi 내부에서 `membersOnly`, `passwordRequired`, Strophe 관련 에러가 콘솔에 대량 출력되어 실제 에러 파악 어려움**

### 발생 환경
- 영향 파일: `kd_features/lobby/middleware.ts` (상단 즉시실행 블록)
- 증상: 참가자가 로비 대기 중 콘솔에 수십 줄의 에러 메시지 출력

### 기존 상태
```
[Error] CONFERENCE FAILED: membersOnly
[Error] connection.passwordRequired
[Error] Strophe error: service-unavailable
[Error] STUN/TURN credentials failed: extdisco
[StropheErrorHandler] Connection failed
...
```

## 🔍 원인 분석

1. **Jitsi 정상 동작 과정**: 로비 모드에서 참가자 입장 시 Jitsi 내부적으로 `membersOnly` 에러를 받고 로비 화면으로 전환하는 것이 **정상 흐름**
2. **에러 레벨 혼용**: Jitsi가 정상 흐름을 `console.error`로 출력해 실제 에러와 구분 불가
3. **Strophe 과도한 로깅**: XMPP 라이브러리가 연결 재시도마다 에러 로그 생성

## ✅ 해결 방법

### 핵심 아이디어
**`console.error`, `window.addEventListener('error')`, `unhandledrejection` 세 레이어에서 로비 관련 에러 필터링 + Strophe 로거 레벨 OFF 설정**

### 구현 코드
```typescript
if (typeof window !== 'undefined') {
    // 1. console.error 필터링
    const originalConsoleError = console.error;
    console.error = function(...args: any[]) {
        const message = args.join(' ');
        if (message.includes('membersOnly')
            || message.includes('Cannot read properties of null')
            || message.includes('reading \'source\'')
            || message.includes('Strophe error')
            || message.includes('service-unavailable')
            || message.includes('STUN/TURN credentials')
            || message.includes('extdisco')) {
            return; // 억제
        }
        originalConsoleError.apply(console, args);
    };

    // 2. 전역 에러 핸들러
    nativeAddEventListener('error', (event: any) => {
        const message = event.message || '';
        if (message.includes('Cannot read properties of null')
            || message.includes('reading \'source\'')) {
            event.preventDefault();
            event.stopImmediatePropagation();
            return false;
        }
    }, true); // 캡처 단계에서 차단

    // 3. Promise rejection 핸들러
    nativeAddEventListener('unhandledrejection', (event: any) => {
        const reasonString = event.reason?.message || String(event.reason || '');
        if (reasonString.includes('connection.passwordRequired')
            || reasonString.includes('service-unavailable')
            || reasonString.includes('STUN/TURN')) {
            event.preventDefault();
            return false;
        }
    });

    // 4. Strophe 로거 레벨 OFF (1초 인터벌로 감시)
    const interval = setInterval(() => {
        if ((window as any).JitsiMeetJS?.loggers) {
            ['xmpp:StropheErrorHandler', 'xmpp:strophe.util'].forEach(name => {
                try { (window as any).JitsiMeetJS.loggers.getLogger(name)?.setLevel('OFF'); }
                catch (e) {}
            });
            clearInterval(interval);
        }
    }, 1000);
    setTimeout(() => clearInterval(interval), 10000); // 10초 후 정리
}
```

## 📊 적용 결과
- 로비 관련 정상 흐름 에러 콘솔 출력 0건
- 실제 에러(네트워크 장애 등)는 여전히 출력됨
- 개발자 디버깅 효율 대폭 향상

## 🎯 검증 방법
1. 참가자 계정으로 로비 대기 진입
2. 브라우저 콘솔에서 membersOnly, Strophe 에러 미출력 확인
3. 실제 네트워크 에러는 정상 출력되는지 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-21/Jitsi enableLobby 타이밍 문제]]
- [[트러블슈팅/2026-06-02/Jitsi beforeunload 차단 패턴]]

---
**해결 완료**: 2026-05-26 | **적용**: kd_features/lobby/middleware.ts | **기법**: 다층 에러 필터링 + Strophe 로거 레벨 제어
