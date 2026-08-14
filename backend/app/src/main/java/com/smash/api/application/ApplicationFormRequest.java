package com.smash.api.application;

import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ApplicationFormRequest {
    private LocalDateTime startDate;
    private LocalDateTime endDate;
}
