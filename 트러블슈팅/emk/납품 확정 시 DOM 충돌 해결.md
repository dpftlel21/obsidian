---
title: 납품 확정 시 DOM 충돌 해결
project: emk
group: EMK
type: troubleshooting
date: 2025-08-19
tags: [emk, 납품, DOM, 리액트, 상태관리]
commits: [07bce2c]
---

# 납품 확정 시 DOM 충돌 해결

## 문제
납품 확정(확정 처리) 시 화면에서 DOM 충돌이 발생했다. 확정 액션 직후 상세 컴포넌트가 갱신되는 과정에서 리액트가 관리하는 DOM과 실제 DOM이 어긋나 오류가 났다.

## 원인
확정 API 성공 후 상세(`DetailDelivery`) 상태 갱신과 목록(`DeliveryStatus`) 리렌더가 동시에 얽히면서, 확정 처리 결과가 캐시/상태에 제대로 반영되지 않고 DOM이 충돌하는 구조였다.

## 해결
- `useDelivery.ts`의 확정 관련 쿼리/뮤테이션 처리를 보강(21라인 추가)하여 확정 후 상태 갱신 흐름을 정리했다.
- `DetailDelivery.tsx`의 렌더 로직을 단순화(16라인 중 상당수 삭제)하여 충돌 지점을 제거했다.

## 관련 파일
- `frontend/src/api/queries/useDelivery.ts`
- `frontend/src/components/vendor/order/DetailDelivery.tsx`, `DeliveryStatus.tsx`

## 관련 노트
- [[납품현황 렌더링 오류 수정]]
