package com.smash.api.schedule;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class FreePeriodController {

    private final FreePeriodService freePeriodService;

    @GetMapping("/api/v1/admin/free-period")
    public ResponseEntity<ApiResponse<FreePeriodResponse>> getCurrent() {
        return ResponseEntity.ok(ApiResponse.success(freePeriodService.getCurrent()));
    }

    @PutMapping("/api/v1/admin/free-period")
    public ResponseEntity<ApiResponse<FreePeriodResponse>> setPeriod(
            @RequestBody @Valid FreePeriodRequest request) {
        return ResponseEntity.ok(ApiResponse.success(freePeriodService.setPeriod(request)));
    }

    @DeleteMapping("/api/v1/admin/free-period")
    public ResponseEntity<ApiResponse<Void>> clear() {
        freePeriodService.clear();
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}