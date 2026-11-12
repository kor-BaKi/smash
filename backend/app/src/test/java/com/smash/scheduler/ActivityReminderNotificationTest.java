package com.smash.scheduler;

import com.smash.api.fcm.FcmService;
import com.smash.api.fcm.PushData;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.ActivityScheduleRepository;
import com.smash.domain.activity.FreePeriodRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

// 활동 마감 임박 알림(1시간 전)이 활동 id를 data로 보내는지 확인한다
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ActivityReminderNotificationTest {

    @Mock ActivityScheduleRepository scheduleRepository;
    @Mock ActivityRepository activityRepository;
    @Mock GroupRepository groupRepository;
    @Mock FreePeriodRepository freePeriodRepository;
    @Mock UserRepository userRepository;
    @Mock FcmService fcmService;
    @Mock ParticipationRepository participationRepository;

    @InjectMocks ActivityScheduler activityScheduler;

    private static final LocalDate TODAY = LocalDate.of(2026, 11, 11); // 수요일
    private static final Long GROUP_ID = 5L;
    private static final Long ACTIVITY_ID = 77L;
    private static final String TITLE = "오늘 활동 마감 임박 ⏰";

    private Activity givenActivity(TimeSlot slot, boolean voteClosed) {
        Group group = Group.builder().dayOfWeek(DayOfWeek.WED).timeSlot(slot).build();
        ReflectionTestUtils.setField(group, "id", GROUP_ID);

        Activity activity = mock(Activity.class);
        given(activity.getId()).willReturn(ACTIVITY_ID);
        given(activity.getGroup()).willReturn(group);
        given(activity.isVoteClosed()).willReturn(voteClosed);
        given(activityRepository.findByActivityDate(TODAY)).willReturn(List.of(activity));
        return activity;
    }

    private User givenMember(Long id, Activity activity, boolean participated) {
        User user = mock(User.class);
        given(user.getId()).willReturn(id);
        given(participationRepository.existsByActivityAndUser(activity, user)).willReturn(participated);
        return user;
    }

    @Test
    @DisplayName("15시 활동은 14시대에 아직 응답하지 않은 조원에게만, 활동 id data와 함께 보낸다")
    void reminder_sendsActivityData_toNonParticipantsOnly() {
        Activity activity = givenActivity(TimeSlot.SLOT_15_17, false);
        User notYet = givenMember(1L, activity, false);
        User done = givenMember(2L, activity, true);
        given(userRepository.findByGroupId(GROUP_ID)).willReturn(List.of(notYet, done));

        activityScheduler.sendActivityReminderNotification(TODAY, LocalTime.of(14, 20));

        verify(fcmService).sendActivityNotificationToUser(
                1L, TITLE, "수 3-5시 활동 참여 여부를 선택해주세요.", PushData.activity(ACTIVITY_ID));
        verify(fcmService, never()).sendActivityNotificationToUser(
                org.mockito.ArgumentMatchers.eq(2L), anyString(), anyString(), anyMap());
    }

    @Test
    @DisplayName("13시 활동은 12시대에 알림을 보낸다")
    void reminder_morningSlot_sentAtTwelve() {
        Activity activity = givenActivity(TimeSlot.SLOT_13_15, false);
        User notYet = givenMember(1L, activity, false);
        given(userRepository.findByGroupId(GROUP_ID)).willReturn(List.of(notYet));

        activityScheduler.sendActivityReminderNotification(TODAY, LocalTime.of(12, 0));

        verify(fcmService).sendActivityNotificationToUser(
                1L, TITLE, "수 1-3시 활동 참여 여부를 선택해주세요.", PushData.activity(ACTIVITY_ID));
    }

    @Test
    @DisplayName("시작 1시간 전이 아니면 보내지 않는다")
    void reminder_wrongHour_notSent() {
        Activity activity = givenActivity(TimeSlot.SLOT_15_17, false);
        User notYet = givenMember(1L, activity, false);
        given(userRepository.findByGroupId(GROUP_ID)).willReturn(List.of(notYet));

        activityScheduler.sendActivityReminderNotification(TODAY, LocalTime.of(13, 20));

        verify(fcmService, never()).sendActivityNotificationToUser(
                anyLong(), anyString(), anyString(), anyMap());
    }

    @Test
    @DisplayName("이미 마감된 활동에는 보내지 않는다")
    void reminder_voteClosed_notSent() {
        Activity activity = givenActivity(TimeSlot.SLOT_15_17, true);
        User notYet = givenMember(1L, activity, false);
        given(userRepository.findByGroupId(GROUP_ID)).willReturn(List.of(notYet));

        activityScheduler.sendActivityReminderNotification(TODAY, LocalTime.of(14, 20));

        verify(fcmService, never()).sendActivityNotificationToUser(
                anyLong(), anyString(), anyString(), anyMap());
    }
}
