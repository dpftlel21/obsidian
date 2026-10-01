# 방장 재입장 membersOnly 루프

## 🚨 문제 상황
**방장이 회의실에서 나갔다 재입장하면 본인이 활성화한 로비 모드에 막혀 `membersOnly` 에러가 반복 발생하며 회의실에 들어오지 못하는 상황**

### 발생 환경
- 영향 파일: `kd_features/lobby/middleware.ts`
- 증상: 방장 재입장 시 `CONFERENCE_FAILED: membersOnly` 에러 반복 → 무한 루프

### 기존 코드 문제점
```typescript
// 기존: membersOnly 에러를 단순 억제만 하고 처리 없음
case CONFERENCE_FAILED:
    const errorString = String(action.error?.message || '');
    if (errorString.includes('membersOnly')) {
        return { ...action, error: null }; // 에러만 억제, 방장은 여전히 못 들어옴
    }
```

## 🔍 원인 분석

```
방장 최초 입장
    │
    ▼
conference.enableLobby() → 로비 모드 ON
    │
    ▼
방장 퇴장 → 로비 모드 유지 (Jitsi 서버 상태)
    │
    ▼
방장 재입장 시도
    │
    ▼
CONFERENCE_FAILED: membersOnly ← 자신이 만든 로비에 막힘
    │
    ▼
에러 억제만 → 재시도 → membersOnly → 무한 루프
```

1. **로비 모드 지속**: 방장이 퇴장해도 Jitsi 서버에 로비 모드가 유지됨
2. **방장도 로비에 막힘**: 로비 모드는 방장 본인에게도 적용됨
3. **자동 처리 부재**: 방장임을 감지하고 자동으로 로비를 우회하는 로직 없음

## ✅ 해결 방법

### 핵심 아이디어
**`CONFERENCE_FAILED`에서 방장 여부를 확인 → 방장이면 로비 화면 숨기고 자동 노킹(`setKnockingState(true)`)으로 우회**

### 구현 코드
```typescript
case CONFERENCE_FAILED:
    const errorString = String(action.error?.message || action.error || '');

    if (errorString.includes('membersOnly') || errorString.includes('passwordRequired')) {

        // 방장인 경우: 로비 화면 자동 숨기고 자동 노킹
        if (lobbyCheckResultGlobal?.isHost) {

            // Jitsi 로비 미들웨어가 openLobbyScreen()을 dispatch하므로
            // 여러 딜레이로 확실히 숨김 처리
            [100, 500, 1000].forEach(delay =>
                setTimeout(() => store.dispatch(hideLobbyScreen()), delay)
            );

            // 방장 자동 노킹: Jitsi 내부 승인 메커니즘으로 자동 입장
            setTimeout(() => {
                store.dispatch(setKnockingState(true));
                store.dispatch(setKdLobbyWaitingForHost(false)); // 방장은 대기 아님
            }, 200);
        }

        return { ...action, error: null }; // 에러 표시 억제
    }
    return next(action);
```

### 방장 재입장 전체 흐름
```
방장 재입장 → CONFERENCE_FAILED(membersOnly)
    │
    ▼
isHost 확인 → true
    │
    ├─ [100ms] hideLobbyScreen()
    ├─ [200ms] setKnockingState(true) → 자동 노킹
    ├─ [500ms] hideLobbyScreen() (재확인)
    └─ [1000ms] hideLobbyScreen() (최종 확인)
        │
        ▼
Jitsi 내부 로비 승인 로직 → 방장 자동 입장
```

## 📊 적용 결과
- 방장 재입장 시 membersOnly 루프 완전 해소
- 자동 노킹으로 로비 우회 후 자동 입장
- 여러 딜레이(100/500/1000ms)로 타이밍 안정화

## 🎯 검증 방법
1. 방장 계정으로 회의 입장 후 로비 활성화 확인
2. 방장 퇴장 후 재입장
3. 로비 화면 없이 자동으로 회의실 재진입 확인
4. 콘솔에 membersOnly 반복 에러 없음 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-06-02/브라우저 강제종료 leave API 호출]]
- [[트러블슈팅/2026-05-21/Jitsi enableLobby 타이밍 문제]]

---
**해결 완료**: 2026-06-02 | **적용**: kd_features/lobby/middleware.ts | **기법**: CONFERENCE_FAILED 방장 감지 + hideLobbyScreen + 자동 노킹
