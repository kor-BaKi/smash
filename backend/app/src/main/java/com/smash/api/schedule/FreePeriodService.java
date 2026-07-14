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

    // 조회 (없으면 null)
    @Transactional(readOnly = true)
    public FreePeriodResponse getCurrent() {
        List<FreePeriod> all = freePeriodRepository.findAll();
        if (all.isEmpty()) return null;
        return FreePeriodResponse.of(all.get(0));
    }

    // 설정 (있으면 덮어쓰기, 없으면 생성)
    @Transactional
    public FreePeriodResponse setPeriod(FreePeriodRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new BusinessException(
                    "INVALID_INPUT", "종료일은 시작일보다 빠를 수 없습니다.");
        }

        List<FreePeriod> existing = freePeriodRepository.findAll();

        if (existing.isEmpty()) {
            FreePeriod created = freePeriodRepository.save(
                    FreePeriod.builder()
                            .startDate(request.getStartDate())
                            .endDate(request.getEndDate())
                            .build());
            return FreePeriodResponse.of(created);
        } else {
            FreePeriod period = existing.get(0);
            period.update(request.getStartDate(), request.getEndDate());

            if (existing.size() > 1) {
                for (int i = 1; i < existing.size(); i++) {
                    freePeriodRepository.delete(existing.get(i));
                }
            }
            return FreePeriodResponse.of(period);
        }
    }

    // 삭제 (자유활동 기간 해제)
    @Transactional
    public void clear() {
        freePeriodRepository.deleteAll();
    }
}