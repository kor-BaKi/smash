package com.smash.domain.group;

// B-1 조 일괄생성 요청을 Service로 넘길 때 쓰는 값 객체. Controller의 DTO에 Service가
// 의존하지 않도록 분리.
public record GroupSlot(DayOfWeek dayOfWeek, TimeSlot timeSlot) {
}
