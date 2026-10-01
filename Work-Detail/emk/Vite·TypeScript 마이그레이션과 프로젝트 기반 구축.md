---
title: Vite·TypeScript 마이그레이션과 프로젝트 기반 구축
project: emk
group: EMK
type: work-detail
date: 2025-03-18
tags: [emk, 인프라, 마이그레이션, vite, typescript]
commits: [2c61ba0, 5430846]
---

# Vite·TypeScript 마이그레이션과 프로젝트 기반 구축

## 개요
EMK 부품/납품 ERP 프론트엔드의 출발점이 된 작업이다. 기존 CRA(Create React App) 기반 JSX 프로젝트를 Vite + TypeScript 스택으로 전환하여 빌드 속도와 타입 안정성을 확보하고, 이후 모든 화면 개발의 기반을 마련했다.

## 주요 커밋
- `2025-03-18` `2c61ba0` Vite 마이그레이션, TypeScript 추가
- `2025-03-18` `5430846` Main 화면 UI 개발

## 구현 내용
- 번들러를 Vite로 교체하고 `vite.config.ts`, `tsconfig.json`을 신규 도입했다.
- 기존 `.jsx` 컴포넌트(Board, Login, Header, Main, Notice, OrderManage, Reference, Sidebar)를 일괄 `.tsx`로 변환하여 타입스크립트 체계로 편입했다.
- `index.html`을 프로젝트 루트로 이동(Vite 규약)하고 진입점 `index.tsx`를 정비했다.
- `package.json` 의존성을 Vite 체계에 맞게 재구성(1000+ 라인 lock 변경)했다.

## 관련 파일
- `frontend/vite.config.ts`, `frontend/tsconfig.json`
- `frontend/index.html`, `frontend/src/index.tsx`, `frontend/src/App.tsx`
- 공통 컴포넌트 `.jsx → .tsx` 변환 다수

## 관련 노트
- [[App.tsx 병합 충돌 해결]]
