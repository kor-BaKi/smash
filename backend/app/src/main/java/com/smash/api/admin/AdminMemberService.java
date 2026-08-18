package com.smash.api.admin;

import com.smash.api.auth.MemberRegisterRequest;
import com.smash.api.auth.MemberRegisterResponse;
import com.smash.common.exception.BusinessException;
import com.smash.domain.availability.MemberAvailabilityRepository;
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
    private final MemberAvailabilityRepository availabilityRepository;

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

    // 지원자 전체 목록 조회 (합격 대기 + 불합격 모두 포함)
    @Transactional(readOnly = true)
    public List<MemberRegisterResponse> getPendingApplicants() {
        return userRepository.findAllApplicants()
                .stream()
                .map(user -> MemberRegisterResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .studentNo(user.getStudentNo())
                        .status(user.getStatus().name())
                        .build())
                .toList();
    }

    // 불합격 처리
    @Transactional
    public void reject(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new com.smash.common.exception.BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 지원자입니다."));

        if (user.getStatus() != Status.PENDING) {
            throw new com.smash.common.exception.BusinessException(
                    "INVALID_STATUS", "대기 상태인 지원자만 불합격 처리할 수 있습니다.");
        }

        user.reject();
    }

    // 불합격 취소 (다시 PENDING으로 복구)
    @Transactional
    public void restore(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new com.smash.common.exception.BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 지원자입니다."));

        if (user.getStatus() != Status.REJECTED) {
            throw new com.smash.common.exception.BusinessException(
                    "INVALID_STATUS", "불합격 상태인 지원자만 복구할 수 있습니다.");
        }

        user.restorePending();
    }

    // 전체 유저 목록 조회 (탈퇴자 제외)
    @Transactional(readOnly = true)
    public List<MemberRegisterResponse> getAllMembers() {
        return userRepository.findAllMembers()
                .stream()
                .map(user -> MemberRegisterResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .studentNo(user.getStudentNo())
                        .status(user.getStatus().name())
                        .role(user.getRole().name())
                        .groupId(user.getGroupId())
                        .build())
                .toList();
    }

    // 특정 조 소속 부원 목록
    @Transactional(readOnly = true)
    public List<MemberRegisterResponse> getGroupMembers(Long groupId) {
        return userRepository.findByGroupId(groupId)
                .stream()
                .map(user -> MemberRegisterResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .studentNo(user.getStudentNo())
                        .status(user.getStatus().name())
                        .role(user.getRole().name())
                        .build())
                .toList();
    }

    @Transactional
    public void deleteMember(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 부원입니다."));
        // 연관 데이터 먼저 삭제 (외래 키 제약)
        availabilityRepository.deleteByUser(user);
        userRepository.delete(user);
    }
}