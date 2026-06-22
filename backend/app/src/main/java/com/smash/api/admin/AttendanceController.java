package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.service.AttendanceService;
import com.smash.service.GroupAttendance;
import com.smash.service.OtherGroupSummary;
import com.smash.service.ShortfallMember;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

// E영역: 전부 임원 전용. /api/v1/admin/** 패턴으로 SecurityConfig가 이미 ROLE_ADMIN을 강제한다.
@RestController
@RequestMapping("/api/v1/admin/attendance")
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    @GetMapping
    public ApiResponse<AttendanceResponse> getAttendance(
            @RequestParam Long groupId, @RequestParam int year, @RequestParam int month) {
        GroupAttendance attendance = attendanceService.getGroupAttendance(groupId, year, month);
        return ApiResponse.success(AttendanceResponse.from(attendance));
    }

    @GetMapping("/shortfall")
    public ApiResponse<List<ShortfallItem>> getShortfall(@RequestParam int year, @RequestParam int month) {
        List<ShortfallMember> members = attendanceService.getShortfallMembers(year, month);
        return ApiResponse.success(members.stream().map(ShortfallItem::from).toList());
    }

    @GetMapping("/other-group")
    public ApiResponse<List<OtherGroupItem>> getOtherGroup(@RequestParam int year, @RequestParam int month) {
        List<OtherGroupSummary> summaries = attendanceService.getOtherGroupSummary(year, month);
        return ApiResponse.success(summaries.stream().map(OtherGroupItem::from).toList());
    }
}
