---
type: project-creator
tags: [automation, templater, quick-create]
---

# 🚀 프로젝트 자동 생성기

## 버튼식 프로젝트 생성

### ⚡ 빠른 프로젝트 링크들
- 🔥 [[Templates/프로젝트 트래커 (칸반 연동)|긴급 프로젝트 생성]]
- 📊 [[Templates/프로젝트 트래커 (칸반 연동)|일반 프로젝트 생성]]
- ⚡ [[Templates/빠른 작업 기록|빠른 작업 기록]]
- 📅 [[Templates/자동화 템플릿/Daily Task Calendar|일일 계획 생성]]

## Templater 자동화 스크립트

### 프로젝트 상세정보 자동 입력
```javascript
<%*
const projectName = await tp.system.prompt("프로젝트명을 입력하세요");
const priority = await tp.system.suggester(["🔥높음", "📊보통", "📝낮음"], ["high", "medium", "low"]);
const expectedDays = await tp.system.prompt("예상 완료일 (며칠 후?)");
const assignee = await tp.system.prompt("담당자");

const startDate = tp.date.now("YYYY-MM-DD");
const endDate = tp.date.now("YYYY-MM-DD", "+" + expectedDays + "d");
%>

---
date: <% startDate %>
project: "<% projectName %>"
status: "진행중"
priority: <% priority %>
assignee: <% assignee %>
expected_end: <% endDate %>
type: project-tracker
tags: [프로젝트, 칸반, 트래킹, <% priority %>]
---

# 🚀 <% projectName %> - 프로젝트 트래커

## 📋 프로젝트 개요
- **시작일**: <% startDate %>
- **예상 완료일**: <% endDate %>
- **진행률**: 0%
- **담당자**: <% assignee %>
- **우선순위**: <% priority %>

## 📊 칸반 보드 (자동 생성됨)

### 📝 계획 (Planned)
- [ ] #<% projectName %> [작업명 입력] 📅 <% startDate %> 🏷️ 계획

### 🔄 진행중 (In Progress)
- [ ] #<% projectName %> [현재 작업] 📅 <% startDate %> 🏷️ 진행중

### 👀 리뷰 (Review)
- [ ] #<% projectName %> [리뷰 대상] 📅 <% startDate %> 🏷️ 리뷰

### ✅ 완료 (Done)
- [ ] #<% projectName %> [완료 작업] 📅 <% startDate %> 🏷️ 완료
```

## 핫키 설정 가이드
1. **Ctrl+Shift+P**: 새 프로젝트 생성
2. **Ctrl+Shift+T**: 빠른 작업 기록
3. **Ctrl+Shift+D**: 일일 계획 생성
4. **Ctrl+Shift+K**: 칸반보드 열기

## 프로젝트 종류별 템플릿

### 🔥 긴급 프로젝트
- 우선순위: 높음
- 기본 기간: 1-3일
- 알림: 매일 체크

### 📊 정규 프로젝트  
- 우선순위: 보통
- 기본 기간: 1-2주
- 알림: 주간 체크

### 📝 장기 프로젝트
- 우선순위: 낮음
- 기본 기간: 1개월+
- 알림: 월간 체크

---
#automation #templater #project-creation #quick-access