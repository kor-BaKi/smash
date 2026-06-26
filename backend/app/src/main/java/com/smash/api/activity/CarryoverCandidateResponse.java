package com.smash.api.activity;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class CarryoverCandidateResponse { // 이월 버튼을 눌렀을 때 달력에 보여줄 날짜 목록을 담는 DTO

    private Long targetActivityId; // 이월 대상 Activity의 id
    private LocalDate date; // 화면에 표시할 날짜
    private String status; // 이 날짜가 미래인지 과거인지 구분

    /*
        지금이 6월 26일(금요일)이고, 부원이 금요일 조 소속이라고 가정합니다.
        부원이 오늘 6/26 활동에서 이월 버튼을 누르면 서버가 이런 응답을 줍니다.

        [
           { "targetActivityId": 5, "date": "2026-07-04", "status": "FUTURE" },
           { "targetActivityId": 3, "date": "2026-06-20", "status": "PAST_ABSENT" }
        ]

     */

}
