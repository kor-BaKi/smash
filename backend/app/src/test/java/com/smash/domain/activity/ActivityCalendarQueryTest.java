package com.smash.domain.activity;

import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
class ActivityCalendarQueryTest {

    @Autowired ActivityRepository activityRepository;
    @Autowired FreePeriodRepository freePeriodRepository;
    @Autowired GroupRepository groupRepository;

    private Group groupA; // 월 1-3시
    private Group groupB; // 월 3-5시

    @BeforeEach
    void setUp() {
        groupA = groupRepository.save(Group.builder()
                .dayOfWeek(DayOfWeek.MON).timeSlot(TimeSlot.SLOT_13_15).build());
        groupB = groupRepository.save(Group.builder()
                .dayOfWeek(DayOfWeek.MON).timeSlot(TimeSlot.SLOT_15_17).build());
    }

    private Activity activity(Group group, LocalDate date, boolean cancelled) {
        Activity a = Activity.builder()
                .group(group)
                .activityDate(date)
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build();
        a.cancel(cancelled);
        return activityRepository.save(a);
    }

    private FreePeriod period(LocalDate start, LocalDate end) {
        return freePeriodRepository.save(FreePeriod.builder().startDate(start).endDate(end).build());
    }

    @Test
    @DisplayName("취소 포함 조회: 월 경계를 포함하고, 다른 조와 다른 달은 제외하며, 날짜순이다")
    void findAllActivitiesByGroupAndMonth_includesCancelled_inclusiveBounds() {
        activity(groupA, LocalDate.of(2026, 10, 31), false);  // 전달 말일: 제외
        Activity first = activity(groupA, LocalDate.of(2026, 11, 1), false);
        Activity cancelled = activity(groupA, LocalDate.of(2026, 11, 16), true);
        Activity last = activity(groupA, LocalDate.of(2026, 11, 30), false);
        activity(groupA, LocalDate.of(2026, 12, 1), false);   // 다음달 1일: 제외
        activity(groupB, LocalDate.of(2026, 11, 9), false);   // 다른 조: 제외

        List<Activity> result = activityRepository.findAllActivitiesByGroupAndMonth(
                groupA.getId(), LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30));

        assertThat(result).extracting(Activity::getId)
                .containsExactly(first.getId(), cancelled.getId(), last.getId());
        assertThat(result.get(1).isCancelled()).isTrue();
    }

    @Test
    @DisplayName("기존 조회(findActivitiesByGroupAndMonth)는 여전히 취소된 활동을 제외한다")
    void existingQuery_stillExcludesCancelled() {
        activity(groupA, LocalDate.of(2026, 11, 2), false);
        activity(groupA, LocalDate.of(2026, 11, 9), true);

        List<Activity> result = activityRepository.findActivitiesByGroupAndMonth(
                groupA.getId(), LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30));

        assertThat(result).extracting(Activity::getActivityDate)
                .containsExactly(LocalDate.of(2026, 11, 2));
    }

    @Test
    @DisplayName("자유 활동 기간 겹침 조회: 하루라도 겹치면 포함하고 시작일순으로 정렬한다")
    void findOverlapping_returnsPeriodsTouchingRange() {
        period(LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31));   // 끝이 범위 시작 하루 전: 제외
        FreePeriod touchesStart = period(LocalDate.of(2026, 10, 20), LocalDate.of(2026, 11, 1));
        FreePeriod inside = period(LocalDate.of(2026, 11, 10), LocalDate.of(2026, 11, 12));
        FreePeriod touchesEnd = period(LocalDate.of(2026, 11, 30), LocalDate.of(2026, 12, 10));
        FreePeriod spanning = period(LocalDate.of(2026, 10, 15), LocalDate.of(2026, 12, 31));
        period(LocalDate.of(2026, 12, 1), LocalDate.of(2026, 12, 5));    // 시작이 범위 끝 다음날: 제외

        List<FreePeriod> result = freePeriodRepository.findOverlapping(
                LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30));

        assertThat(result).extracting(FreePeriod::getId)
                .containsExactly(spanning.getId(), touchesStart.getId(), inside.getId(), touchesEnd.getId());
    }
}
