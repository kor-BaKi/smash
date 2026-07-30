package com.smash.domain.poll;

import com.smash.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

public interface PollVoteRepository extends JpaRepository<PollVote, Long> {
    Optional<PollVote> findByPollAndUser(Poll poll, User user);

    @Query("SELECT v.option.id, COUNT(v) FROM PollVote v WHERE v.poll = :poll GROUP BY v.option.id")
    List<Object[]> countByOptionForPoll(@Param("poll") Poll poll);

    List<PollVote> findByPoll(Poll poll);

    @Transactional
    void deleteByPollAndUser(Poll poll, User user);
}
