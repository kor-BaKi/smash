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
        String code = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        InviteCode inviteCode = InviteCode.builder()
                .code(code)
                .build();
        return InviteCodeResponse.of(inviteCodeRepository.save(inviteCode));
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
