---
title: iOS 카메라 촬영 이미지 비율·기능 반복 수정
project: emk
group: EMK
type: troubleshooting
date: 2025-10-23
tags: [emk, 카메라, iOS, 이미지, 모바일]
commits: [8074d4e, 9ce97cb, 66e2562, 28831c8, c760d9a, 7ef3cdf, 8733b86]
---

# iOS 카메라 촬영 이미지 비율·기능 반복 수정

## 문제
차량 검사 이미지 촬영 기능을 iOS(아이폰 Safari) 환경에서 사용할 때, 카메라가 정상 동작하지 않거나 촬영된 이미지의 비율이 왜곡되는 문제가 반복적으로 발생했다. 2025-10-22 하루에만 카메라 관련 수정 커밋이 다수 이어졌다.

## 원인
- 모바일 브라우저(특히 iOS Safari)마다 `getUserMedia`/카메라 제약(`facingMode`, 해상도) 처리와 캔버스 캡처 동작이 달라 촬영 실패·오류 alert이 발생했다.
- 촬영 결과를 캔버스로 그릴 때 원본 종횡비를 유지하지 못해 iOS에서 이미지가 늘어나 보였다.

## 해결
- 카메라 모드 변경(`c760d9a`), 촬영 UI 및 오류 alert 처리(`66e2562`, `7ef3cdf`) 등을 반복 수정하며 기기별 동작을 맞춰갔다.
- 최종적으로 `8733b86`에서 `InspectionTable.tsx`의 이미지 비율 계산을 보정(1라인)하여 iOS 비율 왜곡을 해결했다.

## 교훈
모바일 카메라 기능은 실기기(iOS/Android)별 편차가 커서, 데스크톱 검증만으로는 부족하고 실제 단말 테스트를 통한 반복 보정이 필요했다.

## 관련 파일
- `frontend/src/components/test/imageUpload/InspectionTable.tsx`

## 관련 노트
- [[차량 이미지 촬영·조회 (카메라·CORS)]]
- [[이미지 조회 CORS 에러 해결]]
