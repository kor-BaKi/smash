package com.smash.api.application;

import com.smash.common.exception.BusinessException;
import com.smash.domain.application.ApplicationAnswerRepository;
import com.smash.domain.application.ApplicationForm;
import com.smash.domain.application.ApplicationFormRepository;
import com.smash.domain.application.ApplicationMemoRepository;
import com.smash.domain.application.ApplicationRepository;
import com.smash.domain.application.FormQuestionRepository;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.AdditionalAnswers.returnsFirstArg;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ApplicationFormPeriodTest {

    @Mock ApplicationFormRepository formRepository;
    @Mock FormQuestionRepository questionRepository;
    @Mock ApplicationRepository applicationRepository;
    @Mock ApplicationAnswerRepository answerRepository;
    @Mock ApplicationMemoRepository memoRepository;
    @Mock UserRepository userRepository;
    @Mock MemberAvailabilityRepository availabilityRepository;
    @Mock GroupRepository groupRepository;

    @InjectMocks ApplicationService applicationService;

    private static final LocalDateTime START = LocalDateTime.of(2027, 3, 2, 9, 0);
    private static final LocalDateTime END = LocalDateTime.of(2027, 3, 16, 23, 55);

    private ApplicationFormRequest request(LocalDateTime start, LocalDateTime end) {
        ApplicationFormRequest r = mock(ApplicationFormRequest.class);
        given(r.getStartDate()).willReturn(start);
        given(r.getEndDate()).willReturn(end);
        return r;
    }

    private void assertInvalidPeriod(Throwable thrown) {
        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo("INVALID_PERIOD");
        assertThat(thrown).hasMessage("모집 종료 시각은 시작 시각보다 이후로 설정해 주세요.");
    }

    @Test
    @DisplayName("폼 생성: 종료가 시작보다 이르면 INVALID_PERIOD, 저장도 이전 폼 마감도 하지 않는다")
    void createForm_endBeforeStart_rejected() {
        ApplicationForm previous = ApplicationForm.builder().isActive(true).build();
        given(formRepository.findTopByOrderByCreatedAtDesc()).willReturn(Optional.of(previous));

        Throwable thrown = catchThrowable(
                () -> applicationService.createForm(request(END, START)));

        assertInvalidPeriod(thrown);
        verify(formRepository, never()).save(any());
        assertThat(previous.isActive()).isTrue(); // 이전 폼은 그대로 접수 중
    }

    @Test
    @DisplayName("폼 생성: 종료와 시작이 같은 시각이어도 거절한다")
    void createForm_endEqualsStart_rejected() {
        assertInvalidPeriod(catchThrowable(
                () -> applicationService.createForm(request(START, START))));
        verify(formRepository, never()).save(any());
    }

    @Test
    @DisplayName("폼 생성: 종료가 시작보다 이후면 기간이 저장된다")
    void createForm_validPeriod_saved() {
        given(formRepository.findTopByOrderByCreatedAtDesc()).willReturn(Optional.empty());
        given(formRepository.save(any(ApplicationForm.class))).willAnswer(returnsFirstArg());

        applicationService.createForm(request(START, END));

        ArgumentCaptor<ApplicationForm> captor = ArgumentCaptor.forClass(ApplicationForm.class);
        verify(formRepository).save(captor.capture());
        assertThat(captor.getValue().getStartDate()).isEqualTo(START);
        assertThat(captor.getValue().getEndDate()).isEqualTo(END);
    }

    @Test
    @DisplayName("폼 생성: 시작이나 종료가 비어 있으면(기간 미설정) 검증하지 않는다")
    void createForm_partialOrEmptyPeriod_allowed() {
        given(formRepository.findTopByOrderByCreatedAtDesc()).willReturn(Optional.empty());
        given(formRepository.save(any(ApplicationForm.class))).willAnswer(returnsFirstArg());

        applicationService.createForm(request(START, null));
        applicationService.createForm(request(null, END));
        applicationService.createForm(request(null, null));

        verify(formRepository, times(3)).save(any(ApplicationForm.class));
    }

    @Test
    @DisplayName("기간 수정: 종료가 시작보다 이르면 INVALID_PERIOD, 기존 기간은 바뀌지 않는다")
    void updateFormPeriod_endBeforeStart_rejected() {
        ApplicationForm form = ApplicationForm.builder()
                .isActive(true).startDate(START).endDate(END).build();
        given(formRepository.findTopByOrderByCreatedAtDesc()).willReturn(Optional.of(form));

        Throwable thrown = catchThrowable(
                () -> applicationService.updateFormPeriod(request(END, START)));

        assertInvalidPeriod(thrown);
        assertThat(form.getStartDate()).isEqualTo(START);
        assertThat(form.getEndDate()).isEqualTo(END);
    }

    @Test
    @DisplayName("기간 수정: 종료가 시작보다 이후면 기간이 바뀐다")
    void updateFormPeriod_valid_updated() {
        ApplicationForm form = ApplicationForm.builder()
                .isActive(true).startDate(START).endDate(END).build();
        given(formRepository.findTopByOrderByCreatedAtDesc()).willReturn(Optional.of(form));
        LocalDateTime newStart = START.plusDays(1);
        LocalDateTime newEnd = END.plusDays(7);

        applicationService.updateFormPeriod(request(newStart, newEnd));

        assertThat(form.getStartDate()).isEqualTo(newStart);
        assertThat(form.getEndDate()).isEqualTo(newEnd);
    }
}
