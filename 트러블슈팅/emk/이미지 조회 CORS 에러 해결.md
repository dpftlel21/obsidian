---
title: 이미지 조회 CORS 에러 해결
project: emk
group: EMK
type: troubleshooting
date: 2025-10-22
tags: [emk, CORS, 이미지, axios]
commits: [feb2d77]
---

# 이미지 조회 CORS 에러 해결

## 문제
차량 검사 이미지 조회 기능을 붙인 뒤, 서버에 저장된 이미지를 불러올 때 브라우저에서 CORS 에러가 발생해 이미지가 표시되지 않았다.

## 원인
이미지 조회 요청이 axios 인스턴스의 크로스 오리진 설정(요청 도메인/credentials·baseURL 처리)과 맞지 않아, 브라우저의 동일 출처 정책에 의해 응답이 차단되었다.

## 해결
- `frontend/src/api/axios/axios.ts`의 요청 설정을 이미지 조회 오리진에 맞게 수정(2라인 변경)하여 CORS 차단을 해소했다.
- 변경 규모는 작지만, 이미지 조회 기능 전체가 동작 가능해진 핵심 수정이었다.

## 관련 파일
- `frontend/src/api/axios/axios.ts`

## 관련 노트
- [[차량 이미지 촬영·조회 (카메라·CORS)]]
