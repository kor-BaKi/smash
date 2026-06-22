package com.smash.domain.activity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

// Phase 2(자유활동 기간 관리 UI/API)에서 관리 예정. 지금은 엔티티+조회만 두고
// 데이터는 직접 등록한다고 가정(스케줄러가 오늘이 이 기간에 속하는지만 확인).
@Entity
@Table(name = "free_period")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FreePeriod {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 100)
    private String name;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Builder
    private FreePeriod(String name, LocalDate startDate, LocalDate endDate) {
        this.name = name;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public boolean includes(LocalDate date) {
        return !date.isBefore(startDate) && !date.isAfter(endDate);
    }
}
