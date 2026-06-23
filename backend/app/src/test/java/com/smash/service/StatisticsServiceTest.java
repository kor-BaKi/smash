package com.smash.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.smash.common.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.participation.Participation;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.participation.ParticipationType;
import java.time.YearMonth;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class StatisticsServiceTest {

    @Mock
    private AttendanceService attendanceService;
    @Mock
    private GroupRepository groupRepository;
    @Mock
    private ActivityRepository activityRepository;
    @Mock
    private ParticipationRepository participationRepository;

    @InjectMocks
    private StatisticsService statisticsService;

    private Group group(long id, DayOfWeek dayOfWeek, TimeSlot timeSlot) {
        Group group = Group.create(dayOfWeek, timeSlot);
        ReflectionTestUtils.setField(group, "id", id);
        return group;
    }

    @Test
    void TC1_조별비교는_멤버수만큼_보장횟수를_곱해_충족률을_낸다() {
        Group groupA = group(1L, DayOfWeek.MON, TimeSlot.SLOT_13_15);
        when(groupRepository.findAll()).thenReturn(List.of(groupA));
        GroupAttendance attendance = new GroupAttendance(1L, DayOfWeek.MON, TimeSlot.SLOT_13_15, 2026, 6, 4,
                List.of(
                        new MemberAttendance(10L, "A", 4, 4, 0, false),
                        new MemberAttendance(11L, "B", 2, 4, 2, true)));
        when(attendanceService.getGroupAttendance(1L, 2026, 6)).thenReturn(attendance);

        List<GroupComparisonItem> result = statisticsService.getGroupComparison(2026, 6);

        assertThat(result).hasSize(1);
        GroupComparisonItem item = result.get(0);
        assertThat(item.guaranteed()).isEqualTo(8);
        assertThat(item.fulfilled()).isEqualTo(6);
        assertThat(item.shortfallMemberCount()).isEqualTo(1);
        assertThat(item.fulfillmentRate()).isEqualTo(6.0 / 8.0);
    }

    @Test
    void TC2_충족률추이는_groupId가_null이면_전체조를_합산한다() {
        Group groupA = group(1L, DayOfWeek.MON, TimeSlot.SLOT_13_15);
        Group groupB = group(2L, DayOfWeek.TUE, TimeSlot.SLOT_15_17);
        when(groupRepository.findAll()).thenReturn(List.of(groupA, groupB));

        GroupAttendance attendanceA = new GroupAttendance(1L, DayOfWeek.MON, TimeSlot.SLOT_13_15, 2026, 6, 4,
                List.of(new MemberAttendance(10L, "A", 4, 4, 0, false)));
        GroupAttendance attendanceB = new GroupAttendance(2L, DayOfWeek.TUE, TimeSlot.SLOT_15_17, 2026, 6, 4,
                List.of(new MemberAttendance(20L, "B", 1, 4, 3, true)));
        when(attendanceService.getGroupAttendance(1L, 2026, 6)).thenReturn(attendanceA);
        when(attendanceService.getGroupAttendance(2L, 2026, 6)).thenReturn(attendanceB);

        List<MonthlyFulfillment> result =
                statisticsService.getFulfillmentTrend(null, YearMonth.of(2026, 6), YearMonth.of(2026, 6));

        assertThat(result).hasSize(1);
        MonthlyFulfillment monthly = result.get(0);
        assertThat(monthly.guaranteed()).isEqualTo(8);
        assertThat(monthly.fulfilled()).isEqualTo(5);
        assertThat(monthly.fulfillmentRate()).isEqualTo(5.0 / 8.0);
    }

    @Test
    void TC3_보장횟수가_0이면_충족률은_0이다() {
        when(groupRepository.findAll()).thenReturn(List.of());

        List<MonthlyFulfillment> result =
                statisticsService.getFulfillmentTrend(null, YearMonth.of(2026, 6), YearMonth.of(2026, 6));

        assertThat(result.get(0).fulfillmentRate()).isEqualTo(0.0);
    }

    @Test
    void TC4_시작월이_종료월보다_늦으면_예외() {
        assertThatThrownBy(() ->
                statisticsService.getFulfillmentTrend(null, YearMonth.of(2026, 7), YearMonth.of(2026, 6)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void TC5_이월빈도는_월별_CARRYOVER_건수를_센다() {
        Activity activity1 = mock(Activity.class);
        Activity activity2 = mock(Activity.class);
        when(activity1.getId()).thenReturn(100L);
        when(activity2.getId()).thenReturn(101L);
        when(activityRepository.findByActivityDateBetween(
                eq(YearMonth.of(2026, 6).atDay(1)), eq(YearMonth.of(2026, 6).atEndOfMonth())))
                .thenReturn(List.of(activity1, activity2));
        when(participationRepository.findByActivityIdInAndType(List.of(100L, 101L), ParticipationType.CARRYOVER))
                .thenReturn(List.of(mock(Participation.class)));

        List<MonthlyCarryoverCount> result =
                statisticsService.getCarryoverTrend(YearMonth.of(2026, 6), YearMonth.of(2026, 6));

        assertThat(result).containsExactly(new MonthlyCarryoverCount(2026, 6, 1));
    }
}
