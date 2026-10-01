# 브라우저 강제종료 시 leave API 호출

## 🚨 문제 상황
**브라우저 탭 강제종료(X 버튼) 시 `CONFERENCE_WILL_LEAVE` 이벤트가 발화되지 않아 백엔드 `meeting_participants` 테이블에 JOINED 상태가 잔류 → 재입장 시 권한 판별 오류 발생**

### 발생 환경
- 영향 파일: `kd_features/lobby/middleware.ts`
- 증상: 브라우저를 강제 종료한 후 재입장 시 방장/참가자 권한이 꼬이거나 로비 상태가 불일치

### 기존 코드 문제점
```typescript
// 기존: CONFERENCE_WILL_LEAVE에서만 leave API 호출
// → 브라우저 강제종료 시 이 이벤트가 발화되지 않음
case CONFERENCE_WILL_LEAVE:
    await meetingApi.leaveMeeting({ emp_no, room_name }); // 강제종료 시 미실행
```

## 🔍 원인 분석

1. **브라우저 이벤트 한계**: 탭/브라우저 강제종료 시 JavaScript 실행 시간 매우 짧음
2. **비동기 API 불가**: `fetch()`나 `axios.post()`는 페이지 언로드 중 취소됨
3. **Jitsi 이벤트 미발화**: `CONFERENCE_WILL_LEAVE`는 Jitsi 내부에서 정상 퇴장 시에만 발화

```
강제종료 흐름:
브라우저 X 클릭 → 페이지 즉시 언로드 → JS 실행 중단
                                           ↓
                              CONFERENCE_WILL_LEAVE 미발화 → leave API 미호출
                              → 백엔드 JOINED 상태 잔류
```

## ✅ 해결 방법

### 핵심 아이디어
**1) `sessionStorage`에 활성 방 정보 저장 → 2) 다음 방문 시 이전 세션 감지 → 3) `sendBeacon`으로 leave API 호출 (페이지 언로드 중에도 전송 보장)**

### 구현 코드
```typescript
// ① CONFERENCE_JOINED 시 활성 방 저장
function _saveActiveRoom() {
    const empNo = getCurrentUserEmpNo();
    const roomName = _getRoomNameFromUrl();
    if (empNo && roomName) {
        sessionStorage.setItem('kd_active_room',
            JSON.stringify({ empNo, roomName })
        );
    }
}

// ② 미들웨어 최상단 즉시실행 블록 — 이전 세션 감지
try {
    const activeRoomData = sessionStorage.getItem('kd_active_room');

    if (activeRoomData) {
        const { empNo, roomName } = JSON.parse(activeRoomData);
        sessionStorage.removeItem('kd_active_room'); // 즉시 제거 (재진입 방지)

        const body = JSON.stringify({ emp_no: empNo, room_name: roomName });

        try {
            // sendBeacon: 페이지 언로드 중에도 전송 보장, 인증 헤더 불가
            navigator.sendBeacon(
                `${API_BASE_URL}/api/meeting/leave`,
                new Blob([body], { type: 'application/json' })
            );
        } catch {
            // 폴백: fetch keepalive — Authorization 헤더 포함 가능
            const token = tokenStorage.getToken();
            fetch(`${API_BASE_URL}/api/meeting/leave`, {
                method: 'POST',
                body,
                headers: {
                    'Content-Type': 'application/json',
                    ...(token ? { Authorization: `Bearer ${token}` } : {})
                },
                keepalive: true // 페이지 언로드 후에도 요청 유지
            }).catch(() => {});
        }

        window.location.replace('/'); // 메인 페이지로 리다이렉트
    }
} catch {
    // sessionStorage 접근 실패 시 무시
}
```

### sendBeacon vs fetch keepalive 비교

| 항목 | sendBeacon | fetch keepalive |
|------|-----------|-----------------|
| 언로드 중 전송 | ✅ 보장 | ✅ 보장 |
| Authorization 헤더 | ❌ 불가 | ✅ 가능 |
| 응답 수신 | ❌ 불가 | ❌ 불가 |
| 크기 제한 | 64KB | 64KB |

## 📊 적용 결과
- 브라우저 강제종료 후 재입장 시 권한 정상 처리
- 백엔드 JOINED 상태 잔류 문제 해소
- sendBeacon 실패 시 fetch keepalive 폴백으로 커버

## 🎯 검증 방법
1. 회의 입장 후 브라우저 탭 강제종료
2. 백엔드 DB에서 해당 참가자 상태 JOINED → LEFT 전환 확인
3. 같은 계정으로 재입장 시 정상 동작 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-06-02/Jitsi beforeunload 차단 패턴]]
- [[트러블슈팅/2026-06-02/방장 재입장 membersOnly 루프]]

---
**해결 완료**: 2026-06-02 | **적용**: kd_features/lobby/middleware.ts | **기법**: sessionStorage 세션 감지 + sendBeacon + fetch keepalive 폴백
