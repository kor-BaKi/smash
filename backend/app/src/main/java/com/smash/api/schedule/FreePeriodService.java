package com.smash.api.schedule;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.FreePeriod;
import com.smash.domain.activity.FreePeriodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FreePeriodService {

    private final FreePeriodRepository freePeriodRepository;

    // 전체 조회
    @Transactional(readOnly = true)
    public List<FreePeriodResponse> getAll() {
        return freePeriodRepository.findAll().stream()
                .map(FreePeriodResponse::of)
                .sorted((a,b) -> a.getStartDate().compareTo(b.getStartDate()))
                .toList();
    }

    // 추가 (기존 기간과 겹치면 거부)
    @Transactional
    public FreePeriodResponse add(FreePeriodRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new BusinessException(
                    "INVALID_INPUT", "종료일은 시작일보다 빠를 수 없습니다."
            );
        }

        boolean overlaps = freePeriodRepository.findAll().stream()
                .anyMatch(existing ->
                        !request.getStartDate().isAfter(existing.getStartDate()) &&
                                !existing.getStartDate().isAfter(request.getEndDate()));

        if (overlaps) {
            throw new BusinessException(
                    "OVERLAPPING_PERIOD", "이미 등록된 기간과 겹칩니다."
            );
        }

        FreePeriod created = freePeriodRepository.save(
                FreePeriod.builder()
                        .startDate(request.getStartDate()).endDate(request.getEndDate()).build()
        );

        return FreePeriodResponse.of(created);
    }

    // 개발 삭제
    @Transactional
    public void delete(Long id) {
        if (!freePeriodRepository.existsById(id)) {
            throw new BusinessException(
                    "RESOURCE_NOT_FOUND", "해당 기간을 찾을 수 없습니다."
            );
        }
        freePeriodRepository.deleteById(id);
    }
}