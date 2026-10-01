---
title: 차량 이미지 촬영·조회 (카메라·CORS)
project: emk
group: EMK
type: work-detail
date: 2025-10-15
tags: [emk, 이미지, 카메라, CORS, 모바일]
commits: [21763a4, 58a02bc, 762e3be, a12a771, 48db898, 8733b86, 291ec79]
---

# 차량 이미지 촬영·조회 (카메라·CORS)

## 개요
차량 검사 시 현장에서 카메라로 사진을 촬영하고, 촬영된 이미지를 차대번호/발행번호 기준으로 조회하는 이미지 파이프라인을 개발했다. 모바일 카메라 제어와 서버 이미지 조회 시의 CORS 문제 해결이 핵심이었다.

## 주요 커밋
- `2025-10-15` `21763a4`(외 4건) 차량 검사 이미지 촬영 기능 구현
- `2025-10-22` `58a02bc` emk erp 이미지 조회 기능 개발 (ImageSearch 157라인 신규) / `762e3be` 이미지 미리보기 구현
- `2025-10-23` `a12a771` 이미지 조회 기능 개발 / `8733b86` iOS 이미지 비율 조정
- `2025-10-29` `48db898` 차대번호·발행번호 조회 및 그에 따른 이미지 조회 / `291ec79` 불승인 사유 추가

## 구현 내용
- 카메라 촬영 컴포넌트로 후면/전면 카메라 전환, 촬영, 미리보기, 파일 선택 대체 입력을 지원했다.
- 이미지 조회 화면(`ImageSearch.tsx`)에서 차대번호/발행번호로 서버 이미지를 불러와 표시했다.
- iOS Safari에서의 이미지 비율 왜곡을 보정했다.
- 검사 결과에 불승인 사유를 함께 관리하도록 확장했다.

## 관련 파일
- `frontend/src/components/test/imageSearch/ImageSearch.tsx`
- `frontend/src/components/test/imageUpload/InspectionTable.tsx`
- `frontend/src/api/axios/imgSearch.ts`, `frontend/src/api/queries/useImgSearch.ts`

## 관련 노트
- [[이미지 조회 CORS 에러 해결]]
- [[iOS 카메라 촬영 이미지 비율·기능 반복 수정]]
- [[차량 접수·검사 시스템]]
