package com.smash.domain.activity;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ActivityPhotoRepository extends JpaRepository<ActivityPhoto, Long> {
    List<ActivityPhoto> findByActivityOrderByCreatedAtAsc(Activity activity);
    void deleteByActivity(Activity activity);
}
