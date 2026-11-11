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
import com.smash.domain.transport.TaxiSettlement;
import com.smash.domain.transport.TaxiSettlementRepository;
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
    private final TaxiSettlementRepository taxiSettlementRepository;

    @Transactional
    public void withdraw(Long userId, WithdrawRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "사용자를 찾을 수 없습니다."));

        if (user.getDeletedAt() != null) {
            throw new BusinessException("RESOURCE_NOT_FOUND", "이미 탈퇴한 계정입니다.");
        }

        // 비밀번호 확인 (로그인과 같은 횟수 제한 적용)
        String attemptKey = user.getStudentNo();
        if (loginAttemptService.isLocked(attemptKey)) {
            throw new BusinessException(
                    "TOO_MANY_ATTEMPTS", "시도가 너무 많습니다. 잠시 후 다시 시도해 주세요.");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            loginAttemptService.recordFailure(attemptKey);
            throw new BusinessException("INVALID_PASSWORD", "비밀번호가 올바르지 않습니다.");
        }
        loginAttemptService.recordSuccess(attemptKey);

        eraseAccount(user);
    }

    // 계정의 개인정보를 삭제·익명화한다. 본인 탈퇴와 임원의 부원 삭제가 함께 사용한다.
    @Transactional
    public void eraseAccount(User user) {
        if (user.getDeletedAt() != null) {
            throw new BusinessException("RESOURCE_NOT_FOUND", "이미 삭제된 계정입니다.");
        }
        assertNotLastAdmin(user);

        Long userId = user.getId();

        // 개인 데이터 삭제
        refreshTokenRepository.deleteByUserId(userId);
        fcmTokenRepository.deleteByUser(user);
        notificationSettingRepository.findByUser(user).ifPresent(notificationSettingRepository::delete);
        availabilityRepository.deleteByUser(user);
        memberNoteRepository.deleteByMember(user);
        memberNoteRepository.deleteByAdmin(user);

        // 조장·부조장 자리 비움
        for (Group group : groupRepository.findByLeaderUserId(userId)) {
            group.assignLeader(null);
        }
        for (Group group : groupRepository.findByViceLeaderUserId(userId)) {
            group.assignViceLeader(null);
        }

        // 결제자로 올린 정산의 계좌 정보 삭제
        for (TaxiSettlement settlement : taxiSettlementRepository.findByPayer(user)) {
            settlement.clearAccount();
        }

        // 지원서의 개인정보와 답변·메모 정리 (익명화 전의 원래 학번으로 찾는다)
        for (Application application : applicationRepository.findByStudentNo(user.getStudentNo())) {
            applicationAnswerRepository.deleteByApplication(application);
            applicationMemoRepository.deleteByApplication(application);
            application.anonymize();
        }

        // 계정 익명화 (학번은 withdrawn-{id}로 바뀌어 같은 학번을 다시 등록할 수 있음)
        user.withdraw();
    }

    // 마지막 임원은 삭제·탈퇴할 수 없다.
    private void assertNotLastAdmin(User user) {
        if (user.getRole() != Role.ADMIN) {
            return;
        }
        long activeAdmins = userRepository.findAllActiveMembers().stream()
                .filter(u -> u.getRole() == Role.ADMIN)
                .count();
        if (activeAdmins <= 1) {
            throw new BusinessException(
                    "INVALID_REQUEST", "마지막 임원은 탈퇴할 수 없습니다. 다른 임원을 먼저 지정해 주세요.");
        }
    }
}
