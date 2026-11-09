package com.smash.api.auth;

import com.smash.auth.LoginAttemptService;
import com.smash.common.exception.BusinessException;
import com.smash.domain.application.Application;
import com.smash.domain.application.ApplicationAnswerRepository;
import com.smash.domain.application.ApplicationMemoRepository;
import com.smash.domain.application.ApplicationRepository;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.token.RefreshTokenRepository;
import com.smash.domain.user.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WithdrawalService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final LoginAttemptService loginAttemptService;
    private final RefreshTokenRepository refreshTokenRepository;
    private final FcmTokenRepository fcmTokenRepository;
    private final UserNotificationSettingRepository notificationSettingRepository;
    private final MemberAvailabilityRepository availabilityRepository;
    private final MemberNoteRepository memberNoteRepository;
    private final GroupRepository groupRepository;
    private final ApplicationRepository applicationRepository;
    private final ApplicationAnswerRepository applicationAnswerRepository;
    private final ApplicationMemoRepository applicationMemoRepository;

    @Transactional
    public void withdraw(Long userId, WithdrawRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "유저를 찾을 수 없습니다."
                ));
        if (user.getDeletedAt() != null) {
            throw new BusinessException("RESOURCE_NOT_FOUND", "이미 탈퇴한 계정입니다.");
        }

        // 비밀번호 확인
        String attemptKey = user.getStudentNo();
        if (loginAttemptService.isLocked(attemptKey)) {
            throw new BusinessException(
                    "TOO_MANY_ATTEMPTS", "시도가 너무 많습니다. 잠시 후 다시 시도해주세요."
            );
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            loginAttemptService.recordFailure(attemptKey);
            throw new BusinessException("INVALID_PASSWORD", "비밀번호가 올바르지 않습니다.");
        }
        loginAttemptService.recordSuccess(attemptKey);

        // 마지막 임원은 탈퇴불가
        if (user.getRole() == Role.ADMIN) {
            long activeAdmins = userRepository.findAllActiveMembers().stream()
                    .filter(u -> u.getRole() == Role.ADMIN)
                    .count();
            if (activeAdmins <= 1) {
                throw new BusinessException(
                        "INVALID_REQUEST", "마지막 임원은 탈퇴할 수 없습니다. 다른 임원을 먼저 지정해 주세요."
                );
            }
        }

        // 개인 데이터 삭제
        refreshTokenRepository.deleteByUserId(userId);
        fcmTokenRepository.deleteByUser(user);
        notificationSettingRepository.findByUser(user).ifPresent(notificationSettingRepository::delete);
        availabilityRepository.deleteByUser(user);
        memberNoteRepository.deleteByMember(user);
        memberNoteRepository.deleteByAdmin(user);

        // 조장, 부조장 자리 비움
        for (Group group : groupRepository.findByLeaderUserId(userId)) {
            group.assignLeader(null);
        }
        for (Group group : groupRepository.findByViceLeaderUserId(userId)) {
            group.assignViceLeader(null);
        }

        for (Application application : applicationRepository.findByStudentNo(user.getStudentNo())) {
            applicationAnswerRepository.deleteByApplication(application);
            applicationMemoRepository.deleteByApplication(application);
            application.anonymize();
        }

        // 계정 익명화
        user.withdraw();
    }
}
