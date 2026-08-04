package com.smash.api.dues;

import com.smash.common.exception.BusinessException;
import com.smash.domain.dues.DuesPayment;
import com.smash.domain.dues.DuesPaymentRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DuesService {

    private final DuesPaymentRepository duesPaymentRepository;
    private final UserRepository userRepository;

    // 전체 부원 납부 현황 조회
    @Transactional
    public List<DuesResponse> getAll() {
        List<User> members = userRepository.findAllMembers();
        return members.stream()
                .map(user -> DuesResponse.of(user, duesPaymentRepository.existsByUser(user)))
                .toList();
    }

    // 납부 처리
    @Transactional
    public void pay(Long userId) {
        User user = getUser(userId);

        if (duesPaymentRepository.existsByUser(user)) {
            throw new BusinessException("ALREADY_PAID", "이미 납부 처리된 부원입니다.");
        }

        duesPaymentRepository.save(DuesPayment.builder()
                .user(user)
                .build());
    }

    // 납부 취소
    @Transactional
    public void cancel(Long userId) {
        User user = getUser(userId);

        if (!duesPaymentRepository.existsByUser(user)) {
            throw new BusinessException("NOT_PAID", "납부 기록이 없습니다.");
        }

        duesPaymentRepository.deleteByUser(user);
    }

    // 전체 초기화
    @Transactional
    public void reset() {
        duesPaymentRepository.deleteAll();
    }

    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "존재하지 않는 부원입니다."));
    }
}
