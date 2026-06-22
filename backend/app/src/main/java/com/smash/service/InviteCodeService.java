package com.smash.service;

import com.smash.common.BusinessException;
import com.smash.common.ErrorCode;
import com.smash.domain.invite.InviteCode;
import com.smash.domain.invite.InviteCodeRepository;
import java.security.SecureRandom;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class InviteCodeService {

    private static final String CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private static final int CODE_LENGTH = 8;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final InviteCodeRepository inviteCodeRepository;

    @Transactional
    public InviteCode create() {
        return inviteCodeRepository.save(InviteCode.create(generateUniqueCode()));
    }

    @Transactional(readOnly = true)
    public List<InviteCode> getAll() {
        return inviteCodeRepository.findAll();
    }

    @Transactional
    public void updateActive(Long id, boolean active) {
        InviteCode inviteCode = inviteCodeRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.RESOURCE_NOT_FOUND));
        inviteCode.updateActive(active);
    }

    private String generateUniqueCode() {
        String code;
        do {
            code = randomCode();
        } while (inviteCodeRepository.findByCode(code).isPresent());
        return code;
    }

    private String randomCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(CODE_CHARS.charAt(RANDOM.nextInt(CODE_CHARS.length())));
        }
        return sb.toString();
    }
}
