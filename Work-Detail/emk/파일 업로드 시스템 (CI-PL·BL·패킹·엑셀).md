---
title: 파일 업로드 시스템 (CI-PL·BL·패킹·엑셀)
project: emk
group: EMK
type: work-detail
date: 2025-05-12
tags: [emk, 파일업로드, CI/PL, BL, 패킹, 엑셀]
commits: [0d6386c, e291583, fddb84c, 771efdc, 13571fe, 1b7e121, 02fd351, aa97525]
---

# 파일 업로드 시스템 (CI-PL·BL·패킹·엑셀)

## 개요
무역/납품 업무에 필요한 각종 서류(CI/PL, BL, 패킹리스트, FTA/CO) 및 엑셀 파일 업로드/다운로드 시스템을 개발했다. 서류 유형별 업로드 규칙과 입고일 기준 제한 등 업무 규칙을 반영했다.

## 주요 커밋
- `2025-05-07` `0d6386c` 엑셀 파일 업로드 구현
- `2025-05-12` `e291583` BL 업로드 구현 / `fddb84c` CI/PL 업로드 구현
- `2025-06-04` `771efdc` 패킹 업로드시 에러 처리 추가
- `2025-06-17` `1b7e121` 패킹 업로드시 입고일 존재시 파일 수정 금지 추가
- `2025-08-12` `13571fe` 파일업로드 부분 수정 (패킹 선업로드 유도, FTA CO 업로드 가능)
- `2025-09-22` `02fd351` 파일업로드 수정일자 추가 / `2026-01-14` `aa97525` 파일명 추가

## 구현 내용
- `DeliveryFileUpload.tsx`(363라인 대폭 개편)를 중심으로 서류 유형별(CI/PL, BL, 패킹) 업로드 UI와 API(`api/axios/fileUpload.ts`, `useFileUpload.ts`)를 연동했다.
- 패킹리스트 선업로드를 유도하고, 이후 FTA/CO 업로드가 가능하도록 순서 규칙을 반영했다.
- 입고일이 존재하면 파일 수정을 제한하는 업무 규칙과 업로드 에러 처리를 추가했다.
- 업로드 수정일자·파일명 표시를 보강했다.

## 관련 파일
- `frontend/src/components/order/DeliveryFileUpload.tsx`
- `frontend/src/api/axios/fileUpload.ts`, `frontend/src/api/queries/useFileUpload.ts`

## 관련 노트
- [[납품서 작성·조회와 바코드 스캐너]]
