# 경기버스 forEach 에러

## 📅 발생일
2026-02-24

## 🐛 문제 상황
경기도 버스 노선 조회 시 "forEach is not a function" 에러가 간헐적으로 발생

## 🔍 원인 분석
### XML/JSON 파싱 시 데이터 구조 차이
- **버스가 여러 대일 때**: 배열(`[]`) 형태로 반환
- **버스가 1대일 때**: 단일 객체(`{}`) 형태로 반환

### 실제 API 응답 비교
```xml
<!-- 버스 2대 이상 -->
<msgBody>
    <itemList>
        <vehId>경기71아1234</vehId>
        <plateNo>1234</plateNo>
    </itemList>
    <itemList>
        <vehId>경기71아5678</vehId>
        <plateNo>5678</plateNo>
    </itemList>
</msgBody>

<!-- 버스 1대 -->
<msgBody>
    <itemList>
        <vehId>경기71아1234</vehId>
        <plateNo>1234</plateNo>
    </itemList>
</msgBody>
```

### JavaScript 파싱 결과
```javascript
// 여러 대: 배열
buses = [
    {vehId: "경기71아1234", plateNo: "1234"},
    {vehId: "경기71아5678", plateNo: "5678"}
]

// 1대: 객체 (forEach 메서드 없음)
buses = {vehId: "경기71아1234", plateNo: "1234"}
```

## ✅ 해결 방안
### PHP 단에서 배열 정규화
```php
// simplexml_load_string 후 배열 확인
$items = $xml->msgBody->itemList;

// 객체인 경우 배열로 감싸기
if (!isset($items[0])) {
    $items = [$items];
}

foreach ($items as $item) {
    // 정상적인 배열 순회 처리
}
```

### JavaScript 단에서 방어 로직
```javascript
// API 응답 후 배열 확인
if (!Array.isArray(buses)) {
    buses = [buses];
}

// 이제 안전하게 forEach 사용 가능
buses.forEach(bus => {
    console.log(bus.vehId);
});
```

## 🎯 결과
- ✅ 경기도 버스 1대 운행 노선에서도 정상 동작
- ✅ 서울/경기 모든 지역에서 안정적인 버스 정보 조회
- ✅ 예외 처리로 시스템 안정성 향상

## 📚 학습 포인트
1. **XML 파싱 시 단일/복수 요소 처리** 주의 필요
2. **방어적 프로그래밍**: Array.isArray() 활용
3. **공공데이터 API의 일관성 부족** 대응 전략