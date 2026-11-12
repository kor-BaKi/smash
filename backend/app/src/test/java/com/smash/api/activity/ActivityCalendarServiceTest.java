package com.smash.api.activity;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.ActivitySchedule;
import com.smash.domain.activity.ActivityScheduleRepository;
import com.smash.domain.activity.ActivityType;
import com.smash.domain.activity.CreatedBy;
import com.smash.domain.activity.FreePeriod;
import com.smash.domain.activity.FreePeriodRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
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
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ActivityCalendarServiceTest {

    @Mock UserRepository userRepository;
    @Mock GroupRepository groupRepository;
    @Mock ActivityRepository activityRepository;
    @Mock ActivityScheduleRepository activityScheduleRepository;
    @Mock FreePeriodRepository freePeriodRepository;
    @InjectMocks ActivityCalendarService service;

    private static final Long USER_ID = 1L;
    private static final Long GROUP_ID = 3L;

    private User user;
    private Group wedGroup; // 수 1-3시

    @BeforeEach
    void setUp() {
        user = mock(User.class);
        given(user.getGroupId()).willReturn(GROUP_ID);
        given(userRepository.findById(USER_ID)).willReturn(Optional.of(user));

        wedGroup = group(GROUP_ID, DayOfWeek.WED, TimeSlot.SLOT_13_15);
        given(groupRepository.findById(GROUP_ID)).willReturn(Optional.of(wedGroup));

        givenSchedule(DayOfWeek.WED, TimeSlot.SLOT_13_15, true);
        given(freePeriodRepository.findOverlapping(any(), any())).willReturn(List.of());
        given(activityRepository.findAllActivitiesByGroupAndMonth(any(), any(), any()))
                .willReturn(List.of());
    }

    // ---------- 헬퍼 ----------

    private Group group(Long id, DayOfWeek day, TimeSlot slot) {
        Group g = Group.builder().dayOfWeek(day).timeSlot(slot).build();
        ReflectionTestUtils.setField(g, "id", id);
        return g;
    }

    private Activity row(Long id, LocalDate date, ActivityType type, boolean cancelled) {
        Activity a = Activity.builder()
                .group(wedGroup)
                .activityDate(date)
                .activityType(type)
                .createdBy(CreatedBy.AUTO)
                .build();
        ReflectionTestUtils.setField(a, "id", id);
        a.cancel(cancelled);
        return a;
    }

    private void givenSchedule(DayOfWeek day, TimeSlot slot, boolean active) {
        ActivitySchedule schedule = ActivitySchedule.builder()
                .dayOfWeek(day).timeSlot(slot).isActive(active).build();
        given(activityScheduleRepository.findByDayOfWeekAndTimeSlot(day, slot))
                .willReturn(Optional.of(schedule));
    }

    private void givenRows(Activity... rows) {
        given(activityRepository.findAllActivitiesByGroupAndMonth(any(), any(), any()))
                .willReturn(List.of(rows));
    }

    private List<LocalDate> dates(ActivityCalendarResponse response) {
        return response.getActivities().stream()
                .map(ActivityCalendarResponse.Day::getDate)
                .toList();
    }

    private ActivityCalendarResponse.Day dayOf(ActivityCalendarResponse response, LocalDate date) {
        return response.getActivities().stream()
                .filter(d -> d.getDate().equals(date))
                .findFirst()
                .orElseThrow(() -> new AssertionError(date + " 항목이 없음"));
    }

    private void assertBusiness(Throwable thrown, String code) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo(code);
    }

    // ---------- 테스트 ----------

    @Test
    @DisplayName("조 미배정 부원: myGroup은 null, 활동은 비어 있고 자유 활동 기간은 내려준다")
    void unassigned_noGroup_onlyFreePeriods() {
        given(user.getGroupId()).willReturn(null);
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 12, 5))
                .build();
        given(freePeriodRepository.findOverlapping(any(), any())).willReturn(List.of(period));

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 11));

        assertThat(res.getMyGroup()).isNull();
        assertThat(res.getActivities()).isEmpty();
        assertThat(res.getFreePeriods()).hasSize(1);
        assertThat(res.getFreePeriods().get(0).getStartDate()).isEqualTo(LocalDate.of(2026, 11, 20));
        verify(activityRepository, never()).findAllActivitiesByGroupAndMonth(any(), any(), any());
    }

    @Test
    @DisplayName("실제 행은 그대로(취소 포함), 오늘 이후 같은 요일은 예측으로 채운다")
    void actualRows_andProjectedFuture() {
        givenRows(
                row(41L, LocalDate.of(2026, 11, 4), ActivityType.REGULAR, false),
                row(47L, LocalDate.of(2026, 11, 11), ActivityType.REGULAR, true));

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 11));

        assertThat(res.getMyGroup().getGroupId()).isEqualTo(GROUP_ID);
        assertThat(res.getMyGroup().getLabel()).isEqualTo("수 1-3시");
        assertThat(dates(res)).containsExactly(
                LocalDate.of(2026, 11, 4), LocalDate.of(2026, 11, 11),
                LocalDate.of(2026, 11, 18), LocalDate.of(2026, 11, 25));

        ActivityCalendarResponse.Day past = dayOf(res, LocalDate.of(2026, 11, 4));
        assertThat(past.getActivityId()).isEqualTo(41L);
        assertThat(past.isProjected()).isFalse();
        assertThat(past.isCancelled()).isFalse();

        ActivityCalendarResponse.Day cancelledToday = dayOf(res, LocalDate.of(2026, 11, 11));
        assertThat(cancelledToday.getActivityId()).isEqualTo(47L);
        assertThat(cancelledToday.isCancelled()).isTrue();
        assertThat(cancelledToday.isProjected()).isFalse();

        ActivityCalendarResponse.Day future = dayOf(res, LocalDate.of(2026, 11, 18));
        assertThat(future.getActivityId()).isNull();
        assertThat(future.isProjected()).isTrue();
        assertThat(future.isCancelled()).isFalse();
        assertThat(future.getActivityType()).isEqualTo("REGULAR");
    }

    @Test
    @DisplayName("예측은 내 조의 요일에만 만들어진다")
    void projection_onlyOnGroupWeekday() {
        // 2026-11-01은 일요일
        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 1));

        assertThat(dates(res)).containsExactly(
                LocalDate.of(2026, 11, 4), LocalDate.of(2026, 11, 11),
                LocalDate.of(2026, 11, 18), LocalDate.of(2026, 11, 25));
        assertThat(res.getActivities()).allMatch(ActivityCalendarResponse.Day::isProjected);
    }

    @Test
    @DisplayName("스케줄이 비활성이거나 없으면 예측하지 않는다")
    void projection_inactiveSchedule_none() {
        givenSchedule(DayOfWeek.WED, TimeSlot.SLOT_13_15, false);

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 1));
        assertThat(res.getActivities()).isEmpty();

        given(activityScheduleRepository.findByDayOfWeekAndTimeSlot(DayOfWeek.WED, TimeSlot.SLOT_13_15))
                .willReturn(Optional.empty());
        res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 1));
        assertThat(res.getActivities()).isEmpty();
    }

    @Test
    @DisplayName("같은 요일의 다른 시간대 스케줄이 활성이어도 내 조(1-3시)는 예측하지 않는다")
    void projection_sameWeekdayOtherTimeSlot_excluded() {
        givenSchedule(DayOfWeek.WED, TimeSlot.SLOT_13_15, false);  // 내 조의 스케줄은 꺼짐
        givenSchedule(DayOfWeek.WED, TimeSlot.SLOT_15_17, true);   // 같은 요일 다른 시간대는 켜짐

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 1));

        assertThat(res.getActivities()).isEmpty();
        verify(activityScheduleRepository).findByDayOfWeekAndTimeSlot(DayOfWeek.WED, TimeSlot.SLOT_13_15);
        verify(activityScheduleRepository, never())
                .findByDayOfWeekAndTimeSlot(DayOfWeek.WED, TimeSlot.SLOT_15_17);
    }

    @Test
    @DisplayName("자유 활동 기간에 속한 예측일은 FREE, 나머지는 REGULAR")
    void projection_freePeriod_typeFree() {
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 11, 17))
                .endDate(LocalDate.of(2026, 11, 20))
                .build();
        given(freePeriodRepository.findOverlapping(any(), any())).willReturn(List.of(period));

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 11));

        assertThat(dayOf(res, LocalDate.of(2026, 11, 18)).getActivityType()).isEqualTo("FREE");
        assertThat(dayOf(res, LocalDate.of(2026, 11, 25)).getActivityType()).isEqualTo("REGULAR");
        assertThat(res.getFreePeriods()).hasSize(1);
    }

    @Test
    @DisplayName("미래 날짜라도 실제 행이 있으면 예측보다 우선하고 중복되지 않는다")
    void actualRow_winsOverProjection() {
        givenRows(row(60L, LocalDate.of(2026, 11, 18), ActivityType.FREE, false));

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 11));

        assertThat(dates(res)).doesNotHaveDuplicates();
        ActivityCalendarResponse.Day day = dayOf(res, LocalDate.of(2026, 11, 18));
        assertThat(day.getActivityId()).isEqualTo(60L);
        assertThat(day.getActivityType()).isEqualTo("FREE");
        assertThat(day.isProjected()).isFalse();
    }

    @Test
    @DisplayName("오늘과 지난 날짜에 행이 없으면 표시하지 않는다")
    void noRow_todayOrPast_notShown() {
        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 18));

        // 11/4, 11/11(과거), 11/18(오늘)은 행이 없으므로 제외. 11/25만 예측
        assertThat(dates(res)).containsExactly(LocalDate.of(2026, 11, 25));
    }

    @Test
    @DisplayName("월 경계(1일, 말일): 실제 행과 예측이 날짜당 한 건만 나온다")
    void monthBoundary_firstAndLastDay_noDuplicates() {
        // 2028-02-01(화)과 2028-02-29(화)가 모두 화요일
        Group tue = group(GROUP_ID, DayOfWeek.TUE, TimeSlot.SLOT_13_15);
        given(groupRepository.findById(GROUP_ID)).willReturn(Optional.of(tue));
        givenSchedule(DayOfWeek.TUE, TimeSlot.SLOT_13_15, true);
        given(activityRepository.findAllActivitiesByGroupAndMonth(any(), any(), any()))
                .willReturn(List.of(
                        rowOf(tue, 1L, LocalDate.of(2028, 2, 1)),
                        rowOf(tue, 2L, LocalDate.of(2028, 2, 29))));

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2028, 2, LocalDate.of(2028, 1, 15));

        assertThat(dates(res)).containsExactly(
                LocalDate.of(2028, 2, 1), LocalDate.of(2028, 2, 8), LocalDate.of(2028, 2, 15),
                LocalDate.of(2028, 2, 22), LocalDate.of(2028, 2, 29));
        assertThat(dayOf(res, LocalDate.of(2028, 2, 1)).isProjected()).isFalse();
        assertThat(dayOf(res, LocalDate.of(2028, 2, 1)).getActivityId()).isEqualTo(1L);
        assertThat(dayOf(res, LocalDate.of(2028, 2, 29)).isProjected()).isFalse();
        assertThat(dayOf(res, LocalDate.of(2028, 2, 29)).getActivityId()).isEqualTo(2L);
        assertThat(dayOf(res, LocalDate.of(2028, 2, 15)).isProjected()).isTrue();
    }

    @Test
    @DisplayName("월 경계: 다른 달 날짜는 섞이지 않고 조회 범위는 1일~말일이다")
    void monthBoundary_queryRange() {
        service.getCalendar(USER_ID, 2026, 12, LocalDate.of(2026, 11, 11));

        verify(activityRepository).findAllActivitiesByGroupAndMonth(
                GROUP_ID, LocalDate.of(2026, 12, 1), LocalDate.of(2026, 12, 31));
        verify(freePeriodRepository).findOverlapping(
                LocalDate.of(2026, 12, 1), LocalDate.of(2026, 12, 31));
    }

    @Test
    @DisplayName("연도나 월이 비었거나 범위를 벗어나면 INVALID_INPUT")
    void invalidYearMonth_rejected() {
        LocalDate today = LocalDate.of(2026, 11, 11);
        assertBusiness(catchThrowable(() -> service.getCalendar(USER_ID, null, 11, today)), "INVALID_INPUT");
        assertBusiness(catchThrowable(() -> service.getCalendar(USER_ID, 2026, null, today)), "INVALID_INPUT");
        assertBusiness(catchThrowable(() -> service.getCalendar(USER_ID, 2026, 0, today)), "INVALID_INPUT");
        assertBusiness(catchThrowable(() -> service.getCalendar(USER_ID, 2026, 13, today)), "INVALID_INPUT");
        assertBusiness(catchThrowable(() -> service.getCalendar(USER_ID, 1999, 11, today)), "INVALID_INPUT");
        assertBusiness(catchThrowable(() -> service.getCalendar(USER_ID, 2101, 11, today)), "INVALID_INPUT");
    }

    @Test
    @DisplayName("JSON 키: isCancelled, isProjected 로 직렬화되고 cancelled/projected 로는 나오지 않는다")
    void json_keys_areExplicit() throws Exception {
        givenRows(row(41L, LocalDate.of(2026, 11, 4), ActivityType.REGULAR, true));
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 11, 20))
                .endDate(LocalDate.of(2026, 12, 5))
                .build();
        given(freePeriodRepository.findOverlapping(any(), any())).willReturn(List.of(period));

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 11));

        ObjectMapper mapper = new ObjectMapper()
                .registerModule(new JavaTimeModule())
                .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        JsonNode root = mapper.readTree(mapper.writeValueAsString(res));

        assertThat(root.fieldNames()).toIterable()
                .containsExactlyInAnyOrder("year", "month", "myGroup", "activities", "freePeriods");
        assertThat(root.get("myGroup").fieldNames()).toIterable()
                .containsExactlyInAnyOrder("groupId", "label");

        JsonNode first = root.get("activities").get(0);
        assertThat(first.fieldNames()).toIterable()
                .containsExactlyInAnyOrder("date", "activityId", "activityType", "isCancelled", "isProjected");
        assertThat(first.has("cancelled")).isFalse();
        assertThat(first.has("projected")).isFalse();
        assertThat(first.get("date").asText()).isEqualTo("2026-11-04");
        assertThat(first.get("isCancelled").asBoolean()).isTrue();
        assertThat(first.get("isProjected").asBoolean()).isFalse();

        JsonNode projected = root.get("activities").get(1);
        assertThat(projected.get("activityId").isNull()).isTrue();
        assertThat(projected.get("isProjected").asBoolean()).isTrue();

        assertThat(root.get("freePeriods").get(0).get("startDate").asText()).isEqualTo("2026-11-20");
    }

    @Test
    @DisplayName("JSON: 조 미배정이면 myGroup 키는 null 값으로 내려간다")
    void json_unassigned_myGroupNull() throws Exception {
        given(user.getGroupId()).willReturn(null);

        ActivityCalendarResponse res = service.getCalendar(USER_ID, 2026, 11, LocalDate.of(2026, 11, 11));

        ObjectMapper mapper = new ObjectMapper()
                .registerModule(new JavaTimeModule())
                .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        JsonNode root = mapper.readTree(mapper.writeValueAsString(res));

        assertThat(root.has("myGroup")).isTrue();
        assertThat(root.get("myGroup").isNull()).isTrue();
        assertThat(root.get("activities").isArray()).isTrue();
        assertThat(root.get("activities")).isEmpty();
    }

    private Activity rowOf(Group g, Long id, LocalDate date) {
        Activity a = Activity.builder()
                .group(g)
                .activityDate(date)
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build();
        ReflectionTestUtils.setField(a, "id", id);
        return a;
    }
}
