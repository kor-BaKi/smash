package com.smash.api.poll;

import com.smash.common.response.ApiResponse;
import com.smash.domain.poll.PollVote;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class PollController {

    private final PollService pollService;

    // 투표 생성 (ADMIN)
    @PostMapping("/api/v1/admin/polls")
    public ResponseEntity<ApiResponse<PollResponse>> create(
            @AuthenticationPrincipal Long userId,
            @RequestBody @Valid PollRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(pollService.create(userId, request)));
    }

    // 투표 목록 조회 (전체)
    @GetMapping("/api/v1/polls")
    public ResponseEntity<ApiResponse<List<PollResponse>>> getList(
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(pollService.getList(userId)));
    }

    // 투표 상세 조회 (전체)
    @GetMapping("/api/v1/polls/{pollId}")
    public ResponseEntity<ApiResponse<PollResponse>> getDetail(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long pollId
    ) {
        return ResponseEntity.ok(ApiResponse.success(pollService.getDetail(userId, pollId)));
    }

    // 투표 참여 (전체)
    @PostMapping("/api/v1/polls/{pollId}/vote")
    public ResponseEntity<ApiResponse<PollResponse>> vote(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long pollId,
            @RequestBody @Valid PollVoteRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(pollService.vote(userId, pollId, request)));
    }

    // 투표 수동 종료 (ADMIN)
    @PatchMapping("/api/v1/polls/{pollId}/close")
    public ResponseEntity<ApiResponse<Void>> close(
            @PathVariable Long pollId
    ) {
        pollService.close(pollId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

}
