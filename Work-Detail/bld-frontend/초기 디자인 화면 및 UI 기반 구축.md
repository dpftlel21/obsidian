# 초기 디자인 화면 및 UI 기반 구축

## 개요
프로젝트 초기 단계에서 부산 여행 서비스의 전체 화면 디자인을 확정하고, React + TypeScript + Tailwind 기반의 공통 UI 뼈대를 구축했다. 디자인 핸드오프 산출물(design_handoff)과 화면별 시안(login, festival detail, course detail, signup, review, saved 등)을 코드로 옮기는 단계다.

## 주요 구현·변경
- 프로젝트 스캐폴딩: `package.json`, `Dockerfile`, `nginx.conf`, `index.html`, `.gitignore` 초기 구성 및 일러스트/마스코트 이미지 에셋(`public/illust-*.png`, `boogie.png`) 등록.
- 공통 컴포넌트 기반 마련: `src/components/shared/`(Icon, MapPreview, ResponsiveRenderer, index), 반응형 훅 `useBreakpoint`, `useWindowWidth` 도입.
- 로그인 화면 및 마이페이지 상세 화면 개발, `design_handoff_busan_travel_new` 시안(README·design-canvas·screens s10~s15)을 저장소에 반영.

## 관련 커밋
- `2026-05-28` `c5190ba` 클로드 디자인 화면 UI/UX 개발
- `2026-06-15` `edf001a` 로그인 화면 및 마이페이지 상세 화면 개발

관련: [[인증 시스템 - OAuth 로그인 회원가입]]
