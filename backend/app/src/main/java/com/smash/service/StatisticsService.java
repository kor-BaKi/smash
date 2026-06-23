package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.participation.ParticipationRepository;
import com.smash.domain.participation.ParticipationType;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Phase 3 통계: 별도 저장 없이 AttendanceService(E영역)가 이미 계산하는 값을 기간/조 단위로 합산한다.
// 전부 임원 전용(CLAUDE.md 3.4와 동일 선상).
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StatisticsService {

    private final AttendanceService attendanceService;
    private final GroupRepository groupRepository;
    private final ActivityRepository activityRepository;
    private final ParticipationRepository participationRepository;

    public List<MonthlyFulfillment> getFulfillmentTrend(Long groupId, YearMonth from, YearMonth to) {
        if (from.isAfter(to)) {
            throw new BusinessException(ErrorCode.INVALID_DATE_RANGE);
        }
        List<MonthlyFulfillment> result = new ArrayList<>();
        for (YearMonth ym = from; !ym.isAfter(to); ym = ym.plusMonths(1)) {
            int guaranteed = 0;
            int fulfilled = 0;
            if (groupId != null) {
                GroupAttendance attendance = attendanceService.getGroupAttendance(groupId, ym.getYear(), ym.getMonthValue());
                guaranteed = attendance.members().size() * attendance.guaranteedCount();
                fulfilled = sumFulfilled(attendance);
            } else {
                for (Group group : groupRepository.findAll()) {
                    GroupAttendance attendance = attendanceService.getGroupAttendance(group.getId(), ym.getYear(), ym.getMonthValue());
                    guaranteed += attendance.members().size() * attendance.guaranteedCount();
                    fulfilled += sumFulfilled(attendance);
                }
            }
            result.add(new MonthlyFulfillment(ym.getYear(), ym.getMonthValue(), guaranteed, fulfilled, rate(guaranteed, fulfilled)));
        }
        return result;
    }

    public List<GroupComparisonItem> getGroupComparison(int year, int month) {
        return groupRepository.findAll().stream()
                .map(group -> {
                    GroupAttendance attendance = attendanceService.getGroupAttendance(group.getId(), year, month);
                    int fulfilled = sumFulfilled(attendance);
                    int memberGuaranteed = attendance.members().size() * attendance.guaranteedCount();
                    long shortfallCount = attendance.members().stream().filter(MemberAttendance::shortfallExists).count();
                    return new GroupComparisonItem(group.getId(), group.getDayOfWeek(), group.getTimeSlot(),
                            memberGuaranteed, fulfilled, (int) shortfallCount, rate(memberGuaranteed, fulfilled));
                })
                .toList();
    }

    public List<MonthlyCarryoverCount> getCarryoverTrend(YearMonth from, YearMonth to) {
        if (from.isAfter(to)) {
            throw new BusinessException(ErrorCode.INVALID_DATE_RANGE);
        }
        List<MonthlyCarryoverCount> result = new ArrayList<>();
        for (YearMonth ym = from; !ym.isAfter(to); ym = ym.plusMonths(1)) {
            LocalDate monthStart = ym.atDay(1);
            LocalDate monthEnd = ym.atEndOfMonth();
            List<Long> activityIds = activityRepository.findByActivityDateBetween(monthStart, monthEnd).stream()
                    .map(Activity::getId)
                    .toList();
            int count = activityIds.isEmpty()
                    ? 0
                    : participationRepository.findByActivityIdInAndType(activityIds, ParticipationType.CARRYOVER).size();
            result.add(new MonthlyCarryoverCount(ym.getYear(), ym.getMonthValue(), count));
        }
        return result;
    }

    private int sumFulfilled(GroupAttendance attendance) {
        return attendance.members().stream().mapToInt(MemberAttendance::fulfilled).sum();
    }

    private double rate(int guaranteed, int fulfilled) {
        return guaranteed == 0 ? 0.0 : (double) fulfilled / guaranteed;
    }
}
