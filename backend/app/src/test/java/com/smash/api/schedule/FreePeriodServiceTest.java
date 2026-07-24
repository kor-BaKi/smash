package com.smash.api.schedule;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.FreePeriod;
import com.smash.domain.activity.FreePeriodRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FreePeriodServiceTest {

    @Mock
    private FreePeriodRepository freePeriodRepository;

    @InjectMocks
    private FreePeriodService freePeriodService;

    @Test
    @DisplayName("자유활동 기간이 없으면 getAll은 빈 리스트를 반환한다")
    void getAll_noPeriods_returnsEmptyList() {
        when(freePeriodRepository.findAll()).thenReturn(Collections.emptyList());

        List<FreePeriodResponse> result = freePeriodService.getAll();

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("종료일이 시작일보다 빠르면 예외가 발생한다")
    void add_endDateBeforeStartDate_throwsException() {
        FreePeriodRequest request = new FreePeriodRequest();
        request.setStartDate(LocalDate.of(2026, 6, 30));
        request.setEndDate(LocalDate.of(2026, 6, 1));

        // findAll() stub 제거 — 이 케이스는 findAll()에 도달하지 않음
        assertThatThrownBy(() -> freePeriodService.add(request))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("겹치는 기간이 있으면 예외가 발생한다")
    void add_overlappingPeriod_throwsException() {
        FreePeriod existing = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 6, 30))
                .build();

        when(freePeriodRepository.findAll()).thenReturn(List.of(existing));

        // 기존 기간(6/1~6/30) 안에 완전히 포함되는 기간
        FreePeriodRequest request = new FreePeriodRequest();
        request.setStartDate(LocalDate.of(2026, 6, 1));
        request.setEndDate(LocalDate.of(2026, 6, 15));

        assertThatThrownBy(() -> freePeriodService.add(request))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    @DisplayName("겹치지 않는 기간은 정상적으로 추가된다")
    void add_nonOverlappingPeriod_success() {
        when(freePeriodRepository.findAll()).thenReturn(Collections.emptyList());
        when(freePeriodRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FreePeriodRequest request = new FreePeriodRequest();
        request.setStartDate(LocalDate.of(2026, 8, 1));
        request.setEndDate(LocalDate.of(2026, 8, 31));

        FreePeriodResponse result = freePeriodService.add(request);

        assertThat(result.getStartDate()).isEqualTo(LocalDate.of(2026, 8, 1));
        assertThat(result.getEndDate()).isEqualTo(LocalDate.of(2026, 8, 31));
        verify(freePeriodRepository, times(1)).save(any());
    }
}