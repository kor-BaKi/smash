package com.smash.domain.activity;

import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "activity_photo")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ActivityPhoto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "activity_id", nullable = false)
    private Activity activity; // 어느 활동의 사진인지

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by", nullable = false)
    private User uploadedBy; // 누가 올렸는지

    @Column(nullable = false)
    private String filePath; // 서버에 저장된 경로

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt; // 업로드 날짜

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public ActivityPhoto(Activity activity, User uploadedBy, String filePath) {
        this.activity = activity;
        this.uploadedBy = uploadedBy;
        this.filePath = filePath;
    }
}
