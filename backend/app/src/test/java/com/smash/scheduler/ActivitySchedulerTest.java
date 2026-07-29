package com.smash.scheduler;

import com.smash.domain.activity.*;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ActivitySchedulerTest {

    @Mock ActivityScheduleRepository scheduleRepository;
    @Mock ActivityRepository activityRepository;
    @Mock GroupRepository groupRepository;
    @Mock FreePeriodRepository freePeriodRepository;

    @InjectMocks ActivityScheduler activityScheduler;

    private Group makeGroup() {
        return Group.builder()
                .dayOfWeek(DayOfWeek.MON)
                .timeSlot(TimeSlot.SLOT_13_15)
                .build();
    }

    @Test
    @DisplayName("자유활동 기간이 아니면 REGULAR 타입으로 활동이 생성된다")
    void createActivityIfNotExists_notFreePeriod_createsRegularActivity() {
        // given
        Group group = makeGroup();
        LocalDate date = LocalDate.of(2026, 7, 1);

        when(activityRepository.findByGroupAndActivityDate(group, date))
                .thenReturn(Optional.empty());
        when(freePeriodRepository.findAll()).thenReturn(List.of()); // 자유활동 기간 없음
        when(activityRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // when
        activityScheduler.createActivityIfNotExists(group, date);

        // then
        ArgumentCaptor<Activity> captor = ArgumentCaptor.forClass(Activity.class);
        verify(activityRepository).save(captor.capture());
        assertThat(captor.getValue().getActivityType()).isEqualTo(ActivityType.REGULAR);
    }

    @Test
    @DisplayName("자유활동 기간이면 FREE 타입으로 활동이 생성된다")
    void createActivityIfNotExists_freePeriod_createsFreeActivity() {
        // given
        Group group = makeGroup();
        LocalDate date = LocalDate.of(2026, 7, 1);

        FreePeriod freePeriod = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 7, 31))
                .build();

        when(activityRepository.findByGroupAndActivityDate(group, date))
                .thenReturn(Optional.empty());
        when(freePeriodRepository.findAll()).thenReturn(List.of(freePeriod));
        when(activityRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // when
        activityScheduler.createActivityIfNotExists(group, date);

        // then
        ArgumentCaptor<Activity> captor = ArgumentCaptor.forClass(Activity.class);
        verify(activityRepository).save(captor.capture());
        assertThat(captor.getValue().getActivityType()).isEqualTo(ActivityType.FREE);
    }

    @Test
    @DisplayName("이미 활동이 있으면 새로 생성하지 않는다")
    void createActivityIfNotExists_alreadyExists_doesNotSave() {
        // given
        Group group = makeGroup();
        LocalDate date = LocalDate.of(2026, 7, 1);

        Activity existing = Activity.builder()
                .group(group)
                .activityDate(date)
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build();

        when(activityRepository.findByGroupAndActivityDate(group, date))
                .thenReturn(Optional.of(existing));

        // when
        activityScheduler.createActivityIfNotExists(group, date);

        // then
        verify(activityRepository, never()).save(any());
    }

    @Test
    @DisplayName("자유활동 기간 경계(시작일)에 FREE 타입으로 생성된다")
    void createActivityIfNotExists_freePeriodStartDate_createsFreeActivity() {
        // given
        Group group = makeGroup();
        LocalDate date = LocalDate.of(2026, 7, 1); // 자유활동 시작일 당일

        FreePeriod freePeriod = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 7, 1))
                .endDate(LocalDate.of(2026, 7, 31))
                .build();

        when(activityRepository.findByGroupAndActivityDate(group, date))
                .thenReturn(Optional.empty());
        when(freePeriodRepository.findAll()).thenReturn(List.of(freePeriod));
        when(activityRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // when
        activityScheduler.createActivityIfNotExists(group, date);

        // then
        ArgumentCaptor<Activity> captor = ArgumentCaptor.forClass(Activity.class);
        verify(activityRepository).save(captor.capture());
        assertThat(captor.getValue().getActivityType()).isEqualTo(ActivityType.FREE);
    }
}