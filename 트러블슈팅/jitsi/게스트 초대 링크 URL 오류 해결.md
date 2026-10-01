---
title: 게스트 초대 링크 URL 오류 해결
group: 화상회의
slug: jitsi
type: troubleshooting
date: 2026-07-23
tags: [화상회의, jitsi, 트러블슈팅, 게스트, 초대, URL]
---

# 게스트 초대 링크 URL 오류 해결

## 문제
외부 게스트에게 발급한 초대 링크의 URL이 올바르게 생성·해석되지 않아 게스트가 회의에 정상 입장하지 못하는 문제가 있었다.

## 원인
게스트 초대 URL 생성 로직이 API 호출 코드(`guestInviteApi.ts`) 안에 섞여 있어, 라우팅(`getRouteToRender.web.ts`)과 정적 페이지(`prejoin.html` 등)에서 기대하는 URL 형식과 어긋났다.

## 해결
- `d55bc3d`에서 URL 생성 로직을 `kd_features/api/meeting/guestInviteUrl.ts`(약 148라인)로 분리하고 `guestInviteApi.ts`를 슬림화했다.
- `guestInviteApi.test.mjs`(약 +62라인) 등 테스트를 추가해 URL 생성 규칙을 검증했다.
- `getRouteToRender.web.ts`의 게스트 라우팅과 정적 페이지(`prejoin.html`, `dialInInfo.html`, `whiteboard.html`)의 경로 참조를 맞췄다.

## 관련 커밋
- `2026-07-23` `d55bc3d` 게스트 초대 기능 URL 수정

## 관련 노트
- [[참여자 초대 및 게스트 링크 초대 기능 구현]]
