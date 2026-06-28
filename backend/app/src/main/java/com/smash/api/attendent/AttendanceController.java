package com.smash.api.attendent;

import com.smash.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    // E-1. 조별 충족 현황
    @GetMapping("/api/m1/admin/attendance")
    public ResponseEntity<ApiResponse<AttendanceResponse>> getAttendance(
            @RequestParam Long groupId,
            @RequestParam int year,
            @RequestParam int month
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.getAttendance(groupId, year, month)
        ));
    }

    // E-2. 미달 부원 필터
    @GetMapping("/api/v1/admin/attendance/shortfall")
    public ResponseEntity<ApiResponse<List<ShortfallResponse>>> getShortfall(
            @RequestParam int year,
            @RequestParam int month
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.getShortfall(year, month)
        ));
    }

    // E-3. 타조참 인원
    @GetMapping("/api/v1/admin/attendance/other-group")
    public ResponseEntity<ApiResponse<List<OtherGroupResponse>>> getOtherGroup(
            @RequestParam int year,
            @RequestParam int month
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.getOtherGroup(year, month)
        ));
    }
}
