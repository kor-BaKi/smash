package com.smash.domain.transport;

import com.smash.domain.user.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "transport_member")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class TransportMember {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transport_group_id", nullable = false)
    private TransportGroup transportGroup;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Builder
    public TransportMember(TransportGroup transportGroup, User user) {
        this.transportGroup = transportGroup;
        this.user = user;
    }
}
