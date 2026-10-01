# IInvitee 타입 오류

## 🚨 문제 상황
**Jitsi 기존 `IInvitee` 타입에 `user_id` 필드가 없어 `inviteKdUsers()` 구현 시 TypeScript 컴파일 에러 발생**

### 발생 환경
- 영향 파일: `features/invite/actions.any.ts`
- 에러 메시지: `Object literal may only specify known properties, and 'user_id' does not exist in type 'IInvitee'`

### 기존 코드 문제점
```typescript
// Jitsi 원본 IInvitee 타입 (user_id 필드 없음)
interface IInvitee {
    type: string;
    id: string;
    name: string;
    // user_id 없음
}

// KD 구현 — user_id 추가하려 했지만 타입 에러
const invitees: IInvitee[] = users.map(user => ({
    type: INVITE_TYPES.USER,
    id: user.emp_no,
    name: user.emp_nm,
    user_id: user.emp_no // ← 타입 에러!
}));
```

## 🔍 원인 분석

1. **Jitsi 타입 정의**: `IInvitee`는 Jitsi 내부 타입으로 KD에서 직접 수정하기 어려움
2. **필드 추가 필요**: KD 백엔드가 `user_id`를 요구하는 초대 API를 사용
3. **타입 충돌**: Jitsi 원본 타입과 KD 요구사항 불일치

## ✅ 해결 방법

### 핵심 아이디어
**타입 확장(interface 병합) 또는 타입 단언으로 `user_id` 필드 허용**

### 구현 코드
```typescript
// actions.any.ts — 타입 단언으로 해결
export function inviteKdUsers(users: ApiEmployee[]) {
    return (dispatch: IStore['dispatch']) => {
        const invitees = users.map(user => ({
            type: INVITE_TYPES.USER,
            id: user.emp_no,
            name: user.emp_nm,
            user_id: user.emp_no  // KD 백엔드용 필드
        })) as IInvitee[]; // 타입 단언으로 컴파일 통과

        return dispatch(invite(invitees, true));
    };
}

// 또는 IInvitee 확장 (더 명시적인 방법)
// features/invite/types.ts에 선언 병합 추가
interface IInvitee {
    user_id?: string; // KD 확장 필드
}
```

## 📊 적용 결과
- TypeScript 컴파일 에러 해소
- `inviteKdUsers()` 액션 정상 동작
- KD 참여자 초대 기능 완성

## 🎯 검증 방법
1. `npm run build` 또는 TypeScript 컴파일 에러 없음 확인
2. 회의 중 조직도에서 직원 선택 후 초대 버튼 클릭
3. 해당 직원 참가 요청 알림 수신 확인

---
**해결 완료**: 2026-05-27 | **적용**: features/invite/actions.any.ts | **기법**: TypeScript 타입 단언
