package com.smash.api.invite;

import com.smash.common.exception.BusinessException;
import com.smash.domain.invite.InviteCode;
import com.smash.domain.invite.InviteCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class InviteCodeService {

    private final InviteCodeRepository inviteCodeRepository;

    @Transactional
    public InviteCodeResponse createInviteCode() {
        String newCode = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        List<InviteCode> existing = inviteCodeRepository.findAll();

        if (existing.isEmpty()) {
            // 없으면 새로 생성
            InviteCode inviteCode = InviteCode.builder()
                    .code(newCode)
                    .build();
            return InviteCodeResponse.of(inviteCodeRepository.save(inviteCode));
        } else {
            // 있으면 기존 것을 재발급 (첫 번째 것 사용, 나머지는 정리)
            InviteCode inviteCode = existing.get(0);
            inviteCode.regenerate(newCode);

            // 혹시 과거에 여러 개 생성됐다면 나머지는 삭제 (정합성 보장)
            if (existing.size() > 1) {
                for (int i = 1; i < existing.size(); i++) {
                    inviteCodeRepository.delete(existing.get(i));
                }
            }

            return InviteCodeResponse.of(inviteCode);
        }
    }

    @Transactional(readOnly = true)
    public List<InviteCodeResponse> getInviteCodes() {
        return inviteCodeRepository.findAll()
                .stream()
                .map(InviteCodeResponse::of)
                .toList();
    }

    @Transactional
    public void toggleInviteCode(Long id, InviteCodeToggleRequest request) {
        InviteCode inviteCode = inviteCodeRepository.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "RESOURE_NOT_FOUND", "존재하지 않는 가입코드입니다."
                ));
        inviteCode.toggleActive(request.isActive());
    }


}
