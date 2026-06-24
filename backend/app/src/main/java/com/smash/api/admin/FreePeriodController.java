package com.smash.api.admin;

import com.smash.common.ApiResponse;
import com.smash.domain.activity.FreePeriod;
import com.smash.service.FreePeriodService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/free-periods")
@RequiredArgsConstructor
public class FreePeriodController {

    private final FreePeriodService freePeriodService;

    @PostMapping
    public ApiResponse<FreePeriodResponse> create(@Valid @RequestBody FreePeriodCreateRequest request) {
        FreePeriod created = freePeriodService.create(request.name(), request.startDate(), request.endDate());
        return ApiResponse.success(FreePeriodResponse.from(created));
    }

    @GetMapping
    public ApiResponse<List<FreePeriodResponse>> getAll() {
        return ApiResponse.success(freePeriodService.getAll().stream().map(FreePeriodResponse::from).toList());
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        freePeriodService.delete(id);
        return ApiResponse.success(null);
    }
}
