package com.smash.api.poll;

import com.smash.common.exception.BusinessException;
import com.smash.domain.poll.*;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PollService {

    private final PollRepository pollRepository;
    private final PollOptionRepository pollOptionRepository;
    private final PollVoteRepository pollVoteRepository;
    private final UserRepository userRepository;

    // 투표 생성 (임원)
    @Transactional
    public PollResponse create(Long userId, PollRequest request) {
        User creator = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "사용자를 찾을 수 없습니다."));

        Poll poll = pollRepository.save(Poll.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .isAnonymous(request.isAnonymous())
                .closedAt(request.getClosedAt())
                .createdBy(creator)
                .build());

        List<String> options = request.getOptions();
        for (int i = 0; i < options.size(); i++) {
            pollOptionRepository.save(PollOption.builder()
                    .poll(poll)
                    .content(options.get(i))
                    .orderIndex(i)
                    .build());
        }

        return getDetail(userId, poll.getId());
    }

    // 투표 목록 조회
    @Transactional(readOnly = true)
    public List<PollResponse> getList(Long userId) {
        return pollRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(poll -> getDetail(userId, poll.getId()))
                .toList();
    }

    // 투표 상세 조회
    @Transactional(readOnly = true)
    public PollResponse getDetail(Long userId, Long pollId) {
        Poll poll = getPoll(pollId);
        List<PollOption> options = pollOptionRepository.findByPollOrderByOrderIndex(poll);

        // 옵션별 투표 수
        Map<Long, Long> voteCounts = new HashMap<>();
        List<Object[]> counts = pollVoteRepository.countByOptionForPoll(poll);
        for (Object[] row : counts) {
            voteCounts.put((Long) row[0], (Long) row[1]);
        }

        // 기명이면 투표자 이름 목록
        Map<Long, List<String>> voterNames = new HashMap<>();
        if (!poll.isAnonymous()) {
            List<PollVote> votes = pollVoteRepository.findByPoll(poll);
            voterNames = votes.stream()
                    .collect(Collectors.groupingBy(
                            v -> v.getOption().getId(),
                            Collectors.mapping(v -> v.getUser().getName(), Collectors.toList())
                    ));
        }

        // 내가 선택한 옵션
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "사용자를 찾을 수 없습니다."));
        Long myVotedOptionId = pollVoteRepository.findByPollAndUser(poll, user)
                .map(v -> v.getOption().getId())
                .orElse(null);

        return PollResponse.of(poll, options, voteCounts, voterNames, myVotedOptionId);
    }

    // 투표 참여
    @Transactional
    public PollResponse vote(Long userId, Long pollId, PollVoteRequest request) {
        Poll poll = getPoll(pollId);

        if (poll.isExpired()) {
            throw new BusinessException("POLL_CLOSED", "종료된 투표입니다.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "사용자를 찾을 수 없습니다."));

        if (pollVoteRepository.findByPollAndUser(poll, user).isPresent()) {
            throw new BusinessException("ALREADY_VOTED", "이미 투표했습니다.");
        }

        PollOption option = pollOptionRepository.findById(request.getOptionId())
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "존재하지 않는 옵션입니다."));

        pollVoteRepository.save(PollVote.builder()
                .poll(poll).option(option).user(user).build());

        return getDetail(userId, pollId);
    }

    @Transactional
    public PollResponse cancelVote(Long userId, Long pollId) {
        Poll poll = getPoll(pollId);

        if (poll.isExpired()) {
            throw new BusinessException("POLL_CLOSED", "종료된 투표는 취소할 수 없습니다.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "사용자를 찾을 수 없습니다."));

        if (pollVoteRepository.findByPollAndUser(poll, user).isEmpty()) {
            throw new BusinessException("NOT_FOUND", "투표한 기록이 없습니다.");
        }

        pollVoteRepository.deleteByPollAndUser(poll, user);
        return getDetail(userId, pollId);
    }

    // 투표 수동 종료 (ADMIN)
    @Transactional
    public void close(Long pollId) {
        Poll poll = getPoll(pollId);
        if (poll.isExpired()) {
            throw new BusinessException("POLL_CLOSED", "이미 종료된 투표입니다.");
        }
        poll.close();
    }



    private Poll getPoll(Long pollId) {
        return pollRepository.findById(pollId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "존재하지 않는 투표입니다."));
    }
}
