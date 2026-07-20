package com.smash.api.schedule;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class FreePeriodController {

    private final FreePeriodService freePeriodService;

    @GetMapping("/api/v1/admin/free-periods")
    public ResponseEntity<ApiResponse<List<FreePeriodResponse>>> getAll() {
        return ResponseEntity.ok(ApiResponse.success(freePeriodService.getAll()));
    }

    @PostMapping("/api/v1/admin/free-periods")
    public ResponseEntity<ApiResponse<FreePeriodResponse>> add(
            @RequestBody @Valid FreePeriodRequest request) {
        return ResponseEntity.ok(ApiResponse.success(freePeriodService.add(request)));
    }

    @DeleteMapping("/api/v1/admin/free-periods/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        freePeriodService.delete(id);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}