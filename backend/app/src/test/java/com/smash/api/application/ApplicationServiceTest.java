package com.smash.api.application;

import com.smash.common.exception.BusinessException;
import com.smash.domain.application.*;
import com.smash.domain.availability.MemberAvailability;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ApplicationServiceTest {

    @Mock ApplicationFormRepository formRepository;
    @Mock FormQuestionRepository questionRepository;
    @Mock ApplicationRepository applicationRepository;
    @Mock ApplicationAnswerRepository answerRepository;
    @Mock ApplicationMemoRepository memoRepository;
    @Mock UserRepository userRepository;
    @Mock MemberAvailabilityRepository availabilityRepository;
    @Mock GroupRepository groupRepository;

    @InjectMocks ApplicationService applicationService;

    private ApplicationForm form;
    private ApplicationSubmitRequest submitRequest;

    @BeforeEach
    void setUp() {
        form = ApplicationForm.builder()
                .isActive(true)
                .build();

        submitRequest = new ApplicationSubmitRequest();
    }

    @Test
    @DisplayName("지원서 제출 성공")
    void submit_success() {
        // given
        given(formRepository.findTopByOrderByCreatedAtDesc())
                .willReturn(Optional.of(form));
        given(applicationRepository.existsByFormAndStudentNo(any(), any()))
                .willReturn(false);
        given(applicationRepository.save(any()))
                .willReturn(Application.builder()
                        .form(form)
                        .name("김동현")
                        .studentNo("2020012060")
                        .department("디지털보안학과")
                        .phone("010-1234-5678")
                        .availabilities("MON:SLOT_13_15")
                        .build());

        // when & then
        assertThatNoException().isThrownBy(() ->
                applicationService.submit(makeSubmitRequest(
                        "김동현", "2020012060", "디지털보안학과",
                        "010-1234-5678", "MON:SLOT_13_15")));
    }

    @Test
    @DisplayName("중복 학번으로 지원 시 예외 발생")
    void submit_duplicateStudentNo_throwsException() {
        // given
        given(formRepository.findTopByOrderByCreatedAtDesc())
                .willReturn(Optional.of(form));
        given(applicationRepository.existsByFormAndStudentNo(any(), any()))
                .willReturn(true);

        // when & then
        assertThatThrownBy(() ->
                applicationService.submit(makeSubmitRequest(
                        "김동현", "2020012060", "디지털보안학과",
                        "010-1234-5678", "MON:SLOT_13_15")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("이미 지원한 학번입니다.");
    }

    @Test
    @DisplayName("폼 비활성화 상태에서 지원 시 예외 발생")
    void submit_formNotActive_throwsException() {
        // given
        ApplicationForm inactiveForm = ApplicationForm.builder()
                .isActive(false)
                .build();
        given(formRepository.findTopByOrderByCreatedAtDesc())
                .willReturn(Optional.of(inactiveForm));

        // when & then
        assertThatThrownBy(() ->
                applicationService.submit(makeSubmitRequest(
                        "김동현", "2020012060", "디지털보안학과",
                        "010-1234-5678", "MON:SLOT_13_15")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("현재 지원 기간이 아닙니다.");
    }

    @Test
    @DisplayName("합격 처리 시 users 테이블 자동 등록")
    void accept_registersUserAutomatically() {
        // given
        Application application = Application.builder()
                .form(form)
                .name("김동현")
                .studentNo("2020012060")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .availabilities("MON:SLOT_13_15")
                .build();

        Group group = Group.builder()
                .dayOfWeek(DayOfWeek.MON)
                .timeSlot(TimeSlot.SLOT_13_15)
                .build();

        User newUser = User.builder()
                .name("김동현")
                .studentNo("2020012060")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .role(Role.MEMBER)
                .status(Status.PENDING)
                .build();

        given(applicationRepository.findById(1L))
                .willReturn(Optional.of(application));
        given(userRepository.existsByStudentNo("2020012060"))
                .willReturn(false);
        given(userRepository.save(any())).willReturn(newUser);
        given(groupRepository.findByDayOfWeekAndTimeSlot(
                DayOfWeek.MON, TimeSlot.SLOT_13_15))
                .willReturn(Optional.of(group));

        // when
        applicationService.accept(1L);

        // then
        verify(userRepository, times(1)).save(any());
        verify(availabilityRepository, times(1)).save(any());
        assertThat(application.getStatus()).isEqualTo(ApplicationStatus.ACCEPTED);
    }

    @Test
    @DisplayName("이미 등록된 학번 합격 처리 시 users 중복 등록 방지")
    void acceptAll_alreadyRegistered_skipsUserRegistration() {
        // given
        Application application = spy(Application.builder()
                .form(form)
                .name("김동현")
                .studentNo("2020012060")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .availabilities("MON:SLOT_13_15")
                .build());

        // PENDING 상태 강제 설정
        given(application.getStatus()).willReturn(ApplicationStatus.PENDING);

        given(formRepository.findTopByOrderByCreatedAtDesc())
                .willReturn(Optional.of(form));
        given(applicationRepository.findByFormOrderByCreatedAtDesc(form))
                .willReturn(List.of(application));
        given(userRepository.existsByStudentNo("2020012060"))
                .willReturn(true);

        // when
        applicationService.acceptAll();

        // then
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("불합격 취소 시 PENDING으로 복구")
    void cancelReject_restoresToPending() {
        // given
        Application application = Application.builder()
                .form(form)
                .name("김동현")
                .studentNo("2020012060")
                .department("디지털보안학과")
                .phone("010-1234-5678")
                .availabilities("MON:SLOT_13_15")
                .build();
        application.reject();

        given(applicationRepository.findById(1L))
                .willReturn(Optional.of(application));

        // when
        applicationService.cancelReject(1L);

        // then
        assertThat(application.getStatus()).isEqualTo(ApplicationStatus.PENDING);
    }

    // 헬퍼 메서드
    private ApplicationSubmitRequest makeSubmitRequest(
            String name, String studentNo, String department,
            String phone, String availabilities) {
        // reflection으로 필드 설정
        ApplicationSubmitRequest request = new ApplicationSubmitRequest();
        try {
            setField(request, "name", name);
            setField(request, "studentNo", studentNo);
            setField(request, "department", department);
            setField(request, "phone", phone);
            String[] pairs = availabilities.split(",");
            List<ApplicationSubmitRequest.AvailabilityRequest> avails =
                    new java.util.ArrayList<>();
            for (String pair : pairs) {
                String[] parts = pair.split(":");
                ApplicationSubmitRequest.AvailabilityRequest avail =
                        new ApplicationSubmitRequest.AvailabilityRequest();
                setField(avail, "dayOfWeek",
                        DayOfWeek.valueOf(parts[0]));
                setField(avail, "timeSlot",
                        TimeSlot.valueOf(parts[1]));
                avails.add(avail);
            }
            setField(request, "availabilities", avails);
            setField(request, "answers", List.of());
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return request;
    }

    private void setField(Object obj, String fieldName, Object value)
            throws Exception {
        var field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
    }
}