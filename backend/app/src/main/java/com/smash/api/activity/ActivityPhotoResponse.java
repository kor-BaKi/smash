package com.smash.api.activity;

import com.smash.domain.activity.ActivityPhoto;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ActivityPhotoResponse {
    private Long id;
    private String url;
    private String uploadedBy;
    private String createdAt;

    public static ActivityPhotoResponse of(ActivityPhoto photo, String baseUrl) {
        return ActivityPhotoResponse.builder()
                .id(photo.getId())
                .url(baseUrl + "/files/photos/" +
                        photo.getFilePath().substring(
                                photo.getFilePath().lastIndexOf("/") + 1
                        ))
                .uploadedBy(photo.getUploadedBy().getName())
                .createdAt(photo.getCreatedAt().toString().substring(0, 16))
                .build();
    }

}
