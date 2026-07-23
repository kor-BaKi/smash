package com.smash.domain.activity;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.TimeSlot;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

public class ActivityTest {

    private Activity makeActivity(LocalDate date, TimeSlot timeSlot) {
        Group group = Group.builder()
                .dayOfWeek(DayOfWeek.MON).timeSlot(timeSlot).build();

        return Activity.builder()
                .group(group)
                .activityDate(date)
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build();
    }

    @Test
    @DisplayName("오늘 1-3시 조는 13시 이전에 투표가 열러있다.")
    void isVoteClosed_slot1315_beforeCloseTime_returnsFalse() {
        // given
        Activity activity = makeActivity(LocalDate.now(), TimeSlot.SLOT_13_15);

        // when & then
        // 현재 시각이 13시 이전이면 false, 이후면 True
        boolean result = activity.isVoteClosed();
        System.out.println("현재 시간 기준 1-3시 조 마감 여부 : " + result);
    }

    @Test
    @DisplayName("과거 날짜의 활동은 항상 투표가 마감")
    void isVoteClosed_pastDate_returnsTrue() {
        // given
        Activity activity = makeActivity(
                LocalDate.now().minusDays(1),
                TimeSlot.SLOT_15_17
        );

        // when
        boolean result = activity.isVoteClosed();

        // then
        assertThat(activity.isVoteClosed()).isTrue();
    }

    @Test
    @DisplayName("미래 날짜의 활동은 항상 투표가 열려 있음")
    void isVoteClosed_futureDate_returnsFalse() {
        Activity activity = makeActivity(
                LocalDate.now().plusDays(1),
                TimeSlot.SLOT_13_15
        );

        assertThat(activity.isVoteClosed()).isFalse();
    }
}
