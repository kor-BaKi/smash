package com.smash.api.schedule;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.time.LocalDate;

@Getter
public class CalendarEventRequest {

    @NotNull(message = "제목을 입력해주세요.")
    private String title;

    @NotNull(message = "날짜를 입력해주세요.")
    private LocalDate date;

    private String memo;

}
