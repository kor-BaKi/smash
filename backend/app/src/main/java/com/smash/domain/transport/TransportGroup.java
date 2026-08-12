package com.smash.domain.transport;

import com.smash.domain.activity.Activity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "transport_group")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class TransportGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "activity_id", nullable = false)
    private Activity activity;

    @Column(nullable = false)
    private int groupNumber;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    @Builder
    public TransportGroup(Activity activity, int groupNumber) {
        this.activity = activity;
        this.groupNumber = groupNumber;
    }
}
