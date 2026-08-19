package com.smash.api.application;

import com.smash.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class ApplicationController {

    private final ApplicationService applicationService;


    // 폼 관리 (ADMIN)


    // 폼 생성
    @PostMapping("/api/v1/admin/application-form")
    public ResponseEntity<ApiResponse<ApplicationFormResponse>> createForm(
            @RequestBody ApplicationFormRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.createForm(request)));
    }

    // 현재 폼 조회 (ADMIN)
    @GetMapping("/api/v1/admin/application-form")
    public ResponseEntity<ApiResponse<ApplicationFormResponse>> getForm() {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.getForm()));
    }

    // 폼 활성/비활성 토글
    @PatchMapping("/api/v1/admin/application-form/toggle")
    public ResponseEntity<ApiResponse<Void>> toggleForm(
            @RequestParam boolean isActive) {
        applicationService.toggleForm(isActive);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 폼 기간 수정
    @PatchMapping("/api/v1/admin/application-form/period")
    public ResponseEntity<ApiResponse<Void>> updateFormPeriod(
            @RequestBody ApplicationFormRequest request) {
        applicationService.updateFormPeriod(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }


    // 질문 관리 (ADMIN)

    // 질문 추가
    @PostMapping("/api/v1/admin/application-form/questions")
    public ResponseEntity<ApiResponse<ApplicationFormResponse>> addQuestion(
            @RequestBody @Valid FormQuestionRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.addQuestion(request)));
    }

    // 질문 삭제
    @DeleteMapping("/api/v1/admin/application-form/questions/{questionId}")
    public ResponseEntity<ApiResponse<ApplicationFormResponse>> deleteQuestion(
            @PathVariable Long questionId) {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.deleteQuestion(questionId)));
    }

    // 질문 순서 변경
    @PatchMapping("/api/v1/admin/application-form/questions/order")
    public ResponseEntity<ApiResponse<ApplicationFormResponse>> reorderQuestions(
            @RequestBody List<Long> questionIds) {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.reorderQuestions(questionIds)));
    }


    // 지원서 (웹 폼)

    // 현재 활성 폼 조회 (웹 폼용 - 인증 불필요)
    @GetMapping("/api/v1/application-form")
    public ResponseEntity<ApiResponse<ApplicationFormResponse>> getActiveForm() {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.getActiveForm()));
    }

    // 지원서 제출 (인증 불필요)
    @PostMapping("/api/v1/applications")
    public ResponseEntity<ApiResponse<Void>> submit(
            @RequestBody @Valid ApplicationSubmitRequest request) {
        applicationService.submit(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }


    // 지원서 관리 (ADMIN)

    // 지원서 목록 조회
    @GetMapping("/api/v1/admin/applications")
    public ResponseEntity<ApiResponse<List<ApplicationResponse>>> getApplications() {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.getApplications()));
    }

    // 지원서 상세 조회
    @GetMapping("/api/v1/admin/applications/{applicationId}")
    public ResponseEntity<ApiResponse<ApplicationResponse>> getApplication(
            @PathVariable Long applicationId) {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.getApplication(applicationId)));
    }

    // 합격 처리
    @PatchMapping("/api/v1/admin/applications/{applicationId}/accept")
    public ResponseEntity<ApiResponse<Void>> accept(
            @PathVariable Long applicationId) {
        applicationService.accept(applicationId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 불합격 처리
    @PatchMapping("/api/v1/admin/applications/{applicationId}/reject")
    public ResponseEntity<ApiResponse<Void>> reject(
            @PathVariable Long applicationId) {
        applicationService.reject(applicationId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 전체 합격 처리
    @PatchMapping("/api/v1/admin/applications/accept-all")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> acceptAll() {
        return ResponseEntity.ok(ApiResponse.success(
                applicationService.acceptAll()));
    }

    // 불합격 취소 (미처리로 복구)
    @PatchMapping("/api/v1/admin/applications/{applicationId}/cancel-reject")
    public ResponseEntity<ApiResponse<Void>> cancelReject(
            @PathVariable Long applicationId) {
        applicationService.cancelReject(applicationId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 메모 수정
    @PatchMapping("/api/v1/admin/applications/{applicationId}/memo")
    public ResponseEntity<ApiResponse<Void>> updateMemo(
            @PathVariable Long applicationId,
            @RequestParam String memo) {
        applicationService.updateMemo(applicationId, memo);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 엑셀 내보내기
    @GetMapping("/api/v1/admin/applications/export")
    public ResponseEntity<byte[]> exportToExcel() {
        byte[] excel = applicationService.exportToExcel();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"applications.xlsx\"")
                .header(HttpHeaders.CONTENT_TYPE,
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                .body(excel);
    }
}

/*
        @RequestParam → URL 파라미터로 받음
          예: PATCH /toggle?isActive=true

        @RequestBody → JSON Body로 받음
          예: { "startDate": "2026-09-01" }
 */