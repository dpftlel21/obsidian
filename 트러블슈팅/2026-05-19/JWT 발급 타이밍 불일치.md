# JWT 발급 타이밍 불일치

## 🚨 문제 상황
**Jitsi WebSocket 연결 시점에 KD 백엔드 JWT가 아직 발급되지 않아 `connection.passwordRequired` 에러 발생**

### 발생 환경
- 영향 파일: `kd_features/kd-dashboard/KdDashboard.tsx`
- 증상: 회의실 URL 진입 시 Jitsi가 바로 WebSocket 연결을 시도하는데, 이 시점에 JWT가 없어 인증 실패

### 기존 코드 문제점
```typescript
// 기존: 회의실 URL로 바로 이동 → JWT 없는 상태에서 Jitsi 연결 시도
const handleJoinMeeting = (meeting: IApiMeeting) => {
    window.location.href = `/${meeting.room_name}`; // JWT 없음
};
```

## 🔍 원인 분석

1. **Jitsi 초기화 순서**: 회의실 URL에 진입하면 Jitsi가 즉시 XMPP/WebSocket 연결 시도
2. **JWT 발급 지연**: KD 백엔드에서 JWT를 발급받으려면 API 호출이 필요 → 비동기
3. **타이밍 충돌**: Jitsi 연결 시도(동기) vs JWT 발급(비동기) 순서가 역전됨

```
기존 흐름:
회의실 URL 진입 → Jitsi 초기화 → WebSocket 연결 시도 (JWT 없음) → passwordRequired 에러
                                         ↓
                              (이 시점에 JWT가 없어서 실패)
```

## ✅ 해결 방법

### 핵심 아이디어
**회의실 URL 진입 전에 JWT를 선발급 받고, JWT를 URL 쿼리 파라미터에 포함시켜 리다이렉트**

### 구현 코드
```typescript
// 해결: joinMeeting API 선호출 → JWT 포함 URL로 리다이렉트
const handleJoinMeeting = async (meeting: IApiMeeting) => {
    const joinRes = await meetingApi.joinMeeting({
        emp_no: user.emp_no,
        room_name: meeting.room_name
    });
    // Jitsi가 페이지 로드 시 URL의 jwt 파라미터를 읽어 인증
    window.location.href = `/${joinRes.room_name}?jwt=${joinRes.jwt}`;
};

// 수정된 흐름:
// joinMeeting API 호출 → JWT 발급 완료 → URL에 jwt= 포함 → 회의실 진입
// → Jitsi 초기화 → URL에서 JWT 읽기 → WebSocket 연결 성공
```

## 📊 적용 결과
- `connection.passwordRequired` 에러 완전 해소
- 방장/참가자 구분 없이 안정적으로 회의실 진입
- joinMeeting API 응답의 `role` 필드로 방장 여부도 동시에 판별 가능

## 🎯 검증 방법
1. 대시보드에서 회의 입장 버튼 클릭
2. 네트워크 탭에서 `/api/meeting/join` 호출 확인
3. 리다이렉트 URL에 `?jwt=eyJ...` 포함 확인
4. Jitsi 회의실 정상 입장 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-20/URL 파라미터 호스트 권한 위조]]

---
**해결 완료**: 2026-05-19 | **적용**: KdDashboard.tsx | **기법**: 비동기 JWT 선발급 후 URL 포함 리다이렉트
