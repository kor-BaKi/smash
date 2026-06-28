package com.smash.domain.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

// JpaRepository<User, Long>에서 User : 다룰 엔티티, Long : PK 타입
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByStudentNo(String studentNo);

    boolean existsByStudentNo(String studentNo);

    int countByGroupId(Long groupId);

    @Query("SELECT u FROM User u WHERE u.groupId IS NULL AND u.status = 'ACTIVE' AND u.deletedAt IS NULL")
    List<User> findUnassignedMembers();

    List<User> findByGroupId(Long groupId);

    @Query("SELECT u FROM User u WHERE u.status = 'ACTIVE' AND u.deletedAt IS NULL")
    List<User> findAllActiveMembers();
}
