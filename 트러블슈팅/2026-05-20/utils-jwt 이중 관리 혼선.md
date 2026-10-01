# utils/jwt.ts 이중 관리 혼선

## 🚨 문제 상황
**`kd_features/utils/jwt.ts`와 `api/auth/tokenStorage.ts`에 JWT 관련 로직이 중복 존재해 충돌 및 혼선 발생**

### 발생 환경
- 영향 파일: `kd_features/utils/jwt.ts` (105줄), `kd_features/api/auth/tokenStorage.ts`
- 증상: JWT 디코드 함수가 두 곳에 있어 import 경로 혼동, 동작 불일치

### 기존 코드 문제점
```typescript
// utils/jwt.ts (삭제 대상) — JWT 디코드·저장 로직 중복
export function decodeJwt(token: string) { ... }
export function getStoredToken() { ... }
export function setStoredToken(token: string) { ... }

// tokenStorage.ts — 동일한 기능이 더 완성된 형태로 존재
export const tokenStorage = {
    getToken: () => localStorage.getItem('kd_token'),
    setToken: (token: string) => localStorage.setItem('kd_token', token),
    ...
};
```

## 🔍 원인 분석

1. **초기 설계 미흡**: 개발 초기 임시로 utils/jwt.ts를 만들었다가 tokenStorage.ts를 정식으로 구축
2. **점진적 확장**: tokenStorage.ts가 완성되면서 jwt.ts는 불필요해졌지만 삭제 누락
3. **import 혼재**: 일부 파일은 jwt.ts를, 일부는 tokenStorage.ts를 import해 동작이 다름

## ✅ 해결 방법

### 핵심 아이디어
**`utils/jwt.ts` 완전 삭제, 모든 참조를 `tokenStorage.ts`와 `authApi.ts`로 통합**

### 구현 코드
```typescript
// 삭제: utils/jwt.ts (105줄 전체 제거)

// tokenStorage.ts로 통합된 최종 인터페이스
export const tokenStorage = {
    getToken: (): string | null => localStorage.getItem('kd_access_token'),
    setToken: (token: string): void => localStorage.setItem('kd_access_token', token),
    removeToken: (): void => localStorage.removeItem('kd_access_token'),
    getUserInfo: (): IUserInfo | null => {
        const token = tokenStorage.getToken();
        if (!token) return null;
        // JWT 디코드 로직 여기서만 관리
        const payload = JSON.parse(atob(token.split('.')[1]));
        return { emp_no: payload.emp_no, emp_nm: payload.emp_nm };
    }
};
```

## 📊 적용 결과
- JWT 관련 로직 단일 진입점(tokenStorage.ts) 확보
- 파일 수 감소: 3개 → 2개
- 코드 라인 감소: 105줄 제거

## 🎯 검증 방법
1. `utils/jwt.ts` import 참조 전체 삭제 확인 (grep으로 검색)
2. tokenStorage 기반 토큰 저장·조회 정상 동작 확인
3. 로그인 후 API 요청에 토큰 정상 첨부 확인

## 📚 관련 이슈
- [[트러블슈팅/2026-05-20/URL 파라미터 호스트 권한 위조]]

---
**해결 완료**: 2026-05-20 | **적용**: utils/jwt.ts 삭제, tokenStorage.ts 통합 | **기법**: 중복 코드 제거 및 단일 책임 원칙
