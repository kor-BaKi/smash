package com.smash.domain.activity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;


public class FreePeriodTest {

    @Test
    @DisplayName("날짜가 자유활동 기간에 있으면 True 반환")
    void contains_dateInsidePeriod_returnTrue() {
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 6, 30))
                .build();

        assertThat(period.contains(LocalDate.of(2026, 6, 15))).isTrue();
    }

    @Test
    @DisplayName("시작일 당일도 자유활동 기간에 포함")
    void contains_startDate_returnsTrue() {
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 6, 30))
                .build();

        assertThat(period.contains(LocalDate.of(2026, 6, 1))).isTrue();
    }

    @Test
    @DisplayName("종료일 당일도 자유활동 기간에 포함")
    void contains_endDate_returnsTrue() {
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 6, 30))
                .build();

        assertThat(period.contains(LocalDate.of(2026, 6, 30))).isTrue();
    }

    @Test
    @DisplayName("날짜가 자유활동 기간 이전이면 False 반환")
    void contains_dateBeforePeriod_returnsFalse() {
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 6, 30))
                .build();

        assertThat(period.contains(LocalDate.of(2026, 5, 31))).isFalse();
    }

    @Test
    @DisplayName("날자까 자유활동 기간 이후이면 False 반환")
    void contains_dateAfterPeriod_returnsFalse() {
        FreePeriod period = FreePeriod.builder()
                .startDate(LocalDate.of(2026, 6, 1))
                .endDate(LocalDate.of(2026, 6, 30))
                .build();

        assertThat(period.contains(LocalDate.of(2026, 7, 1))).isFalse();
    }





}
