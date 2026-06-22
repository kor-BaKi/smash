package com.smash.domain.group;

import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberAvailabilityRepository extends JpaRepository<MemberAvailability, Long> {

    List<MemberAvailability> findByUserId(Long userId);

    List<MemberAvailability> findByUserIdIn(Collection<Long> userIds);

    void deleteByUserId(Long userId);
}
