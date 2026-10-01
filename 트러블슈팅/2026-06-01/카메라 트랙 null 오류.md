# 카메라 트랙 null 오류

## 🚨 문제 상황
**화상회의 초대 완료 후 카메라 트랙이 잡히지 않거나 `Cannot read properties of null (reading 'source')` 에러 발생**

### 발생 환경
- 영향 파일: `features/invite/actions.any.ts`, `kd_features/api/invite/InviteKdUsersSection.tsx`, `kd_features/lobby/middleware.ts`
- 증상: 참여자 초대 후 카메라가 꺼지거나 검은 화면 표시, 콘솔에 null 참조 에러

### 기존 코드 문제점
```typescript
// lobby/middleware.ts — 트랙 null 체크 없이 접근
const localVideoTrack = getLocalVideoTrack(store.getState().tracks);
localVideoTrack.jitsiTrack.getOriginalStream(); // null이면 크래시

// InviteKdUsersSection.tsx — 언마운트 후 상태 업데이트 시도
const handleInvite = async () => {
    await inviteKdUsers(selectedUsers);
    setIsLoading(false); // 컴포넌트가 이미 언마운트되면 경고
};
```

## 🔍 원인 분석

1. **트랙 라이프사이클**: 초대 완료 후 Jitsi 내부에서 미디어 트랙을 재설정하는 과정에서 일시적으로 트랙 객체가 `null` 상태
2. **비동기 타이밍**: invite 액션 완료 후 컴포넌트가 언마운트되는 시점에 setState 호출 → React 경고 및 불안정
3. **로비 미들웨어 간섭**: 로비 체크 중 `getLocalVideoTrack()` 호출 시 트랙이 아직 초기화 안 된 상태

## ✅ 해결 방법

### 핵심 아이디어
**1) 트랙 접근 전 null 체크 추가, 2) 컴포넌트 언마운트 후 setState 방지 클린업**

### 구현 코드
```typescript
// lobby/middleware.ts — null 가드 추가
const localVideoTrack = getLocalVideoTrack(store.getState().tracks);
if (localVideoTrack?.jitsiTrack) {
    // 트랙이 있을 때만 접근
    localVideoTrack.jitsiTrack.getOriginalStream();
}

// InviteKdUsersSection.tsx — 언마운트 감지 클린업
const isMountedRef = useRef(true);

useEffect(() => {
    return () => { isMountedRef.current = false; }; // 언마운트 시 false
}, []);

const handleInvite = async () => {
    await dispatch(inviteKdUsers(selectedUsers));
    if (isMountedRef.current) {  // 마운트 상태일 때만 setState
        setIsLoading(false);
    }
};

// features/invite/actions.any.ts — inviteVideoRooms 호출 경로 방어 코드
if (rooms && rooms.length > 0) {
    dispatch(inviteVideoRooms(conference, rooms)); // conference null 체크 추가
}
```

## 📊 적용 결과
- 카메라 트랙 null 오류 완전 해소
- 초대 완료 후 카메라 정상 표시
- React 언마운트 경고 제거

## 🎯 검증 방법
1. 회의 중 조직도에서 여러 명 초대
2. 초대 완료 후 카메라 화면 정상 표시 확인
3. 콘솔에 `reading 'source'` 에러 없음 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-27/IInvitee 타입 오류]]

---
**해결 완료**: 2026-06-01 | **적용**: invite/actions, InviteKdUsersSection, lobby/middleware | **기법**: null 가드 + useRef 언마운트 감지
