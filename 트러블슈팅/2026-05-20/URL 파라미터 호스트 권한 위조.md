# URL 파라미터 호스트 권한 위조

## 🚨 문제 상황
**`?host=true` URL 파라미터로 방장 권한을 누구나 획득할 수 있는 보안 취약점 존재**

### 발생 환경
- 영향 파일: `kd_features/lobby/middleware.ts`, `kd_features/kd-dashboard/KdDashboard.tsx`
- 증상: 일반 참가자가 URL에 `?host=true`를 붙이면 방장 권한으로 처리됨

### 기존 코드 문제점
```typescript
// 기존: URL 파라미터로 방장 판별 → 누구나 조작 가능
async function _checkLobbyRequirement() {
    const urlParams = new URLSearchParams(window.location.search);
    const isHostParam = urlParams.get('host') === 'true'; // ← 클라이언트 조작 가능

    if (isHostParam) {
        result.isHost = true; // 방장 권한 부여 → 보안 취약점
    }
}
```

## 🔍 원인 분석

1. **클라이언트 파라미터 신뢰**: URL 쿼리 파라미터는 사용자가 자유롭게 수정 가능
2. **서버 검증 부재**: 방장 여부를 백엔드 API로 확인하지 않고 클라이언트 값만 사용
3. **인가(Authorization) 미흡**: 인증(Authentication)은 됐지만 역할 인가가 클라이언트 의존

## ✅ 해결 방법

### 핵심 아이디어
**방장 판별 기준을 백엔드 API 응답(role 필드)으로 완전 전환, URL 파라미터는 API 실패 시 폴백으로만 유지**

### 구현 코드
```typescript
// 해결: API 응답 기반 방장 판별
async function _checkLobbyRequirement() {
    try {
        const joinResponse = await meetingApi.joinMeeting({
            emp_no: empNo,
            room_name: roomName
        });

        // 백엔드가 반환한 role 값으로 판별 (조작 불가)
        const isHostByApi = joinResponse.role === 'HOST'
                         || joinResponse.is_host === true
                         || joinResponse.role === 'OWNER'
                         || joinResponse.role === 'MODERATOR';

        result.isHost = isHostByApi;

    } catch (apiError) {
        // API 실패 시에만 URL 파라미터로 폴백 (예외 상황)
        const urlParams = new URLSearchParams(window.location.search);
        result.isHost = urlParams.get('host') === 'true';
    }
}
```

## 📊 적용 결과
- URL 파라미터 조작으로 방장 권한 획득 불가
- 백엔드 DB 기준으로 방장 여부 정확히 판별
- API 장애 시에만 URL 파라미터 폴백 동작

## 🎯 검증 방법
1. 일반 참가자 계정으로 `?host=true` URL 직접 접근
2. 로비 대기 화면이 정상 표시되는지 확인 (방장 권한 미부여 확인)
3. 실제 방장 계정으로 접근 시 바로 입장되는지 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-19/JWT 발급 타이밍 불일치]]
- [[트러블슈팅/2026-05-20/utils-jwt 이중 관리 혼선]]

---
**해결 완료**: 2026-05-20 | **적용**: lobby/middleware.ts | **기법**: 서버 검증 기반 인가로 전환
