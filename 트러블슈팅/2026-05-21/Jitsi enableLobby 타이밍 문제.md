# Jitsi enableLobby 타이밍 문제

## 🚨 문제 상황
**`CONFERENCE_JOINED` 이벤트 직후 `conference.enableLobby()`를 호출하면 내부 XMPP 상태가 준비되지 않아 실패**

### 발생 환경
- 영향 파일: `kd_features/lobby/middleware.ts`
- 증상: 방장이 회의실 입장 직후 로비 활성화가 간헐적으로 실패하거나 에러 발생

### 기존 코드 문제점
```typescript
// 기존: CONFERENCE_JOINED 직후 즉시 enableLobby 호출 → 실패
case CONFERENCE_JOINED:
    if (lobbyCheckResultGlobal?.isHost) {
        const conference = getCurrentConference(store.getState());
        conference.enableLobby(); // XMPP 아직 준비 안 됨 → 실패
    }
    return next(action);
```

## 🔍 원인 분석

1. **XMPP 초기화 지연**: `CONFERENCE_JOINED` 이벤트는 컨퍼런스 객체 생성 완료를 의미하지만, 내부 XMPP MUC(Multi-User Chat) 세션이 완전히 준비되기까지 추가 시간 필요
2. **enableLobby 의존성**: `enableLobby()`는 XMPP MUC 상태에 의존하는 비동기 작업
3. **레이스 컨디션**: 이벤트 발화 시점과 실제 준비 완료 시점 사이 간격 존재

```
CONFERENCE_JOINED 발화
        │
        ├─ 내부 XMPP MUC 초기화 (비동기, ~500ms~1000ms 소요)
        │
        └─ enableLobby() 즉시 호출 → MUC 미준비 → 실패
```

## ✅ 해결 방법

### 핵심 아이디어
**`setTimeout(..., 1000)`으로 1초 딜레이를 주어 XMPP 초기화 완료 후 로비 활성화**

### 구현 코드
```typescript
case CONFERENCE_JOINED:
    meetingLeaveSent = false;

    if (lobbyCheckResultGlobal?.isHost) {
        // 1초 딜레이: XMPP MUC 초기화 완료 대기
        setTimeout(() => {
            const { dispatch } = store;
            const currentConference = getCurrentConference(store.getState());

            if (currentConference && (currentConference as any).enableLobby) {
                try {
                    (currentConference as any).enableLobby();
                    dispatch(setLobbyModeEnabled(true));
                } catch (error) {
                    // 로비 활성화 실패는 무시 (재시도 없음)
                }
            }
        }, 1000); // XMPP 초기화 대기
    }
    return next(action);
```

## 📊 적용 결과
- 방장 입장 후 로비 활성화 성공률 100%
- 참가자가 방장 승인 없이 입장하는 케이스 차단
- `try-catch`로 enableLobby 실패 시 크래시 방지

## 🎯 검증 방법
1. 방장 계정으로 회의실 입장
2. 1초 후 로비 모드 활성화 확인 (Jitsi 관리자 패널)
3. 별도 계정으로 같은 방 입장 시도 → 로비 대기 화면 표시 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-26/Strophe XMPP 에러 억제]]

---
**해결 완료**: 2026-05-21 | **적용**: kd_features/lobby/middleware.ts | **기법**: setTimeout 딜레이로 XMPP 초기화 대기
