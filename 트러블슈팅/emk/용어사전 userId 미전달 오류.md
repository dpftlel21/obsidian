---
title: 용어사전 userId 미전달 오류
project: emk
group: EMK
type: troubleshooting
date: 2025-09-22
tags: [emk, 용어사전, userId, API]
commits: [808f3ec]
---

# 용어사전 userId 미전달 오류

## 문제
용어사전 기능 사용 시 서버로 `userId`가 넘어가지 않아, 사용자 식별이 필요한 용어 등록/조회 처리가 정상 동작하지 않았다.

## 원인
`Glossary.tsx`에서 API 호출 시 요청 파라미터에 `userId`가 누락되어 있었다.

## 해결
- `Glossary.tsx`(1라인 수정)에서 요청에 `userId`를 포함하도록 보정하여 문제를 해결했다.
- 용어사전 페이지 개발 직후 발견된 회귀로, 한 줄 수정으로 즉시 처리되었다.

## 관련 파일
- `frontend/src/components/common/Glossary.tsx`

## 관련 노트
- [[용어사전과 번역 기능]]
