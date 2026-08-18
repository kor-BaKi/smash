package com.smash.api.application;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.TimeSlot;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;

import java.util.List;

@Getter
public class ApplicationSubmitRequest {

    @NotBlank(message = "이름을 입력해주세요.")
    private String name;

    @NotBlank(message = "학번을 입력해주세요.")
    private String studentNo;

    @NotBlank(message = "학과를 입력해주세요.")
    private String department;

    @NotBlank(message = "전화 번호를 입력해주세요.")
    private String phone;

    @NotEmpty(message = "희망 활동 시간을 선택해주세요.")
    private List<AvailabilityRequest> availabilities;

    private List<AnswerRequest> answers;

    @Getter
    public static class AvailabilityRequest {
        private DayOfWeek dayOfWeek;
        private TimeSlot timeSlot;
    }

    @Getter
    public static class AnswerRequest {
        private Long questionId;
        private String answer;
    }
}
