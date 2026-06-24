package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.activity.FreePeriod;
import com.smash.domain.activity.FreePeriodRepository;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FreePeriodService {

    private final FreePeriodRepository freePeriodRepository;

    @Transactional
    public FreePeriod create(String name, LocalDate startDate, LocalDate endDate) {
        if (startDate.isAfter(endDate)) {
            throw new BusinessException(ErrorCode.INVALID_DATE_RANGE);
        }
        return freePeriodRepository.save(FreePeriod.create(name, startDate, endDate));
    }

    @Transactional(readOnly = true)
    public List<FreePeriod> getAll() {
        return freePeriodRepository.findAll();
    }

    @Transactional
    public void delete(Long id) {
        if (!freePeriodRepository.existsById(id)) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND);
        }
        freePeriodRepository.deleteById(id);
    }
}
