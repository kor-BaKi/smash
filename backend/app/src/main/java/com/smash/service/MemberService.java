package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class MemberService {

    private final UserRepository userRepository;

    // A-1: 임원의 합격자 단건 사전등록. role=MEMBER, status=PENDING, password=NULL.
    @Transactional
    public User registerPending(String name, String studentNo, String department, String phone, String joinTerm) {
        if (userRepository.existsByStudentNo(studentNo)) {
            throw new BusinessException(ErrorCode.ALREADY_REGISTERED);
        }
        return userRepository.save(User.createPending(name, studentNo, department, phone, joinTerm));
    }

    // A-2: 대량등록 부분성공. 건별로 검증해서 실패해도 나머지는 계속 진행한다
    // (예외를 던지지 않고 결과를 누적하므로, 하나의 @Transactional 안에서도 전체 롤백이 일어나지 않는다).
    @Transactional
    public MemberBulkRegisterResult registerPendingBulk(List<MemberRegisterCommand> commands) {
        List<MemberRegisterSucceeded> succeeded = new ArrayList<>();
        List<MemberRegisterFailed> failed = new ArrayList<>();

        for (MemberRegisterCommand command : commands) {
            if (!StringUtils.hasText(command.name())
                    || !StringUtils.hasText(command.studentNo())
                    || !StringUtils.hasText(command.joinTerm())) {
                failed.add(new MemberRegisterFailed(command.studentNo(), "MISSING_REQUIRED"));
                continue;
            }
            if (userRepository.existsByStudentNo(command.studentNo())) {
                failed.add(new MemberRegisterFailed(command.studentNo(), "DUPLICATE"));
                continue;
            }
            User saved = userRepository.save(User.createPending(
                    command.name(), command.studentNo(), command.department(), command.phone(), command.joinTerm()));
            succeeded.add(new MemberRegisterSucceeded(command.studentNo(), saved.getId()));
        }
        return new MemberBulkRegisterResult(succeeded, failed, commands.size());
    }
}
