package com.smash.domain.availability;

import com.smash.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MemberAvailabilityRepository extends JpaRepository<MemberAvailability, Long> {
    List<MemberAvailability> findByUser(User user);

    void deleteByUser(User user);

    List<MemberAvailability> findByGroupId(Long groupId);
}
