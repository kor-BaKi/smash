package com.smash.api.admin;

import com.smash.api.auth.MemberRegisterRequest;
import com.smash.api.auth.MemberRegisterResponse;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminMemberService {

    private final UserRepository userRepository;

    // A-1. 단건 등록
    @Transactional
    public MemberRegisterResponse registerMember(MemberRegisterRequest request) {
        if (userRepository.existsByStudentNo(request.getStudentNo())) {
            throw new com.smash.common.exception.BusinessException(
                    "ALREADY_REGISTERED", "이미 등록된 학번입니다.");
        }

        User user = User.builder()
                .name(request.getName())
                .studentNo(request.getStudentNo())
                .department(request.getDepartment())
                .phone(request.getPhone())
                .joinTerm(request.getJoinTerm())
                .role(Role.MEMBER)
                .status(Status.PENDING)
                .build();

        User saved = userRepository.save(user);

        return MemberRegisterResponse.builder()
                .id(saved.getId())
                .name(saved.getName())
                .studentNo(saved.getStudentNo())
                .status(saved.getStatus().name())
                .build();
    }

    // A-2. 대량 등록 (부분 성공)
    public MemberRegisterResponse.BulkResponse registerMembers(
            MemberRegisterRequest.BulkRequest request) {

        List<MemberRegisterResponse> succeeded = new ArrayList<>();
        List<MemberRegisterResponse.FailedItem> failed = new ArrayList<>();

        for (MemberRegisterRequest member : request.getMembers()) {
            try {
                // registerMember() 대신 로직을 직접 실행
                if (userRepository.existsByStudentNo(member.getStudentNo())) {
                    failed.add(MemberRegisterResponse.FailedItem.builder()
                            .studentNo(member.getStudentNo())
                            .reason("ALREADY_REGISTERED")
                            .build());
                    continue;
                }

                User user = User.builder()
                        .name(member.getName())
                        .studentNo(member.getStudentNo())
                        .department(member.getDepartment())
                        .phone(member.getPhone())
                        .joinTerm(member.getJoinTerm())
                        .role(Role.MEMBER)
                        .status(Status.PENDING)
                        .build();

                User saved = userRepository.save(user);
                succeeded.add(MemberRegisterResponse.builder()
                        .id(saved.getId())
                        .name(saved.getName())
                        .studentNo(saved.getStudentNo())
                        .status(saved.getStatus().name())
                        .build());

            } catch (Exception e) {
                failed.add(MemberRegisterResponse.FailedItem.builder()
                        .studentNo(member.getStudentNo())
                        .reason("UNKNOWN_ERROR")
                        .build());
            }
        }

        return MemberRegisterResponse.BulkResponse.builder()
                .succeeded(succeeded)
                .failed(failed)
                .totalRequested(request.getMembers().size())
                .successCount(succeeded.size())
                .build();
    }
}