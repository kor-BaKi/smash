package com.smash.api.activity;

import com.smash.common.response.ApiResponse;
import com.smash.domain.activity.ActivityPhotoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ActivityPhotoController {

    private final ActivityPhotoRepository activityPhotoRepository;
    private final ActivityPhotoService activityPhotoService;

    // 사진 업로드
    @PostMapping("/api/v1/admin/activities/{activityId}/photos")
    public ResponseEntity<ApiResponse<List<ActivityPhotoResponse>>> upload(
            @PathVariable Long activityId,
            @RequestParam("files") List<MultipartFile> files,
            @AuthenticationPrincipal Long userId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                activityPhotoService.upload(activityId, files, userId)
        ));
    }

    // 사진 목록 조회
    @GetMapping("/api/v1/admin/activities/{activityId}/photos")
    public ResponseEntity<ApiResponse<List<ActivityPhotoResponse>>> getPhotos(
            @PathVariable Long activityId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                activityPhotoService.getPhotos(activityId)
        ));
    }

    // 사진 삭제
    @DeleteMapping("/api/v1/admin/activities/photos/{photoId}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long photoId
    ) {
        activityPhotoService.delete(photoId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    // 파일 서빙
    @GetMapping("/files/photos/{filename}")
    public ResponseEntity<byte[]> serveFile(
            @PathVariable String filename
    ) {
        return activityPhotoService.serveFile(filename);
    }


}
