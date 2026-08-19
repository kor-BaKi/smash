package com.smash.domain.user;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MemberNoteRepository extends JpaRepository<MemberNote, Long> {
    List<MemberNote> findByMemberAndAdminOrderByCreatedAtAsc(User member, User admin);
    void deleteById(Long id);
}