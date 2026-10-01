---
title: Q&A·자료실·문의 게시판 개발
project: emk
group: EMK
type: work-detail
date: 2025-07-16
tags: [emk, QnA, 자료실, 문의]
commits: [1a06d4f, 45ff7c7, 9a234f0, 77e5818, 60692d1, 28a902d, 107553f]
---

# Q&A·자료실·문의 게시판 개발

## 개요
거래처와의 소통 채널인 Q&A(문의), 자료실 기능을 개발했다. 문의 작성/수정/삭제, 파일 업로드/다운로드, 유저 메뉴에서 문의내역 바로가기까지 제공한다.

## 주요 커밋
- `2025-07-07` `1a06d4f` Q&A 화면 개발 / `9a234f0` 유저 메뉴 문의내역 이동하기 추가
- `2025-07-08` `45ff7c7` Q&A API 기능 개발
- `2025-07-15` `77e5818` Q&A 수정 및 파일 업로드 구현
- `2025-07-16` `60692d1` Q&A 수정·삭제 구현 / `28a902d` 파일 다운로드 구현 / `e413ff2` file_name2 파일 조회 추가
- `2025-07-22` `107553f` 자료실, tooltip 개발

## 구현 내용
- Q&A 박스 컴포넌트(`Q&ABox.tsx`, `Q&AItem.tsx`)와 API(`api/axios/qna.ts`, `useSearchBoard.ts`)를 연동해 문의 등록/조회/수정/삭제를 구현했다.
- 문의 첨부파일 업로드 및 다중 파일(`file_name2`) 조회·다운로드를 지원했다.
- 자료실 화면(`Reference.tsx`)과 항목 설명용 tooltip을 추가했다.
- 유저 메뉴에서 본인 문의내역으로 바로 이동하는 진입점을 제공했다.

## 관련 파일
- `frontend/src/common/q&a/Q&ABox.tsx`, `Q&AItem.tsx`
- `frontend/src/api/axios/qna.ts`, `frontend/src/api/queries/useSearchBoard.ts`
- `frontend/src/common/reference/Reference.tsx`

## 관련 노트
- [[게시판·공지사항 시스템과 필터링]]
- [[파일 업로드 시스템 (CI-PL·BL·패킹·엑셀)]]
