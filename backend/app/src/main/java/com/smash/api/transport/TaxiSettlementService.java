package com.smash.api.transport;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.transport.*;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaxiSettlementService {

    private final TaxiSettlementRepository settlementRepository;
    private final TaxiSettlementPaymentRepository paymentRepository;
    private final TransportGroupRepository transportGroupRepository;
    private final TransportMemberRepository transportMemberRepository;
    private final ActivityRepository activityRepository;
    private final UserRepository userRepository;


    // 정산 생성
    @Transactional
    public TaxiSettlementResponse create(
            Long activityId, Long groupId,
            TaxiSettlementRequest request, Long payerId
    ) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 활동입니다."));

        TransportGroup group = transportGroupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 호차입니다."));

        User payer = userRepository.findById(payerId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."));

        // 이미 정산이 있으면 예외 처리
        if (settlementRepository.findByTransportGroup(group).isPresent()) {
            throw new BusinessException("ALREADY_EXISTS", "이미 정산이 등록되어 있습니다.");
        }

        // 탑승자 수로 1인당 금액 계산
        List<TransportMember> members =
                transportMemberRepository.findByTransportGroup(group);
        int amountPerPerson = request.getTotalAmount() / members.size();

        TaxiSettlement settlement = settlementRepository.save(
                TaxiSettlement.builder()
                        .transportGroup(group)
                        .activity(activity)
                        .payer(payer)
                        .totalAmount(request.getTotalAmount())
                        .amountPerPerson(amountPerPerson)
                        .accountBank(request.getAccountBank())
                        .accountNumber(request.getAccountNumber())
                        .build()
        );

        // 결제자 제외 동승자 납부 현황 생성
        for (TransportMember member : members) {
            if (!member.getUser().getId().equals(payerId)) {
                paymentRepository.save(
                        TaxiSettlementPayment.builder()
                                .settlement(settlement).user(member.getUser()).build()
                );
            }
        }

        List<TaxiSettlementPayment> payments =
                paymentRepository.findBySettlement(settlement);
        return TaxiSettlementResponse.of(settlement, payments);
    }

    // 정산 조회
    @Transactional(readOnly = true)
    public TaxiSettlementResponse getSettlement(Long activityId, Long groupId) {
        TransportGroup group = transportGroupRepository.findById(groupId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 호차입니다."));

        TaxiSettlement settlement = settlementRepository
                .findByTransportGroup(group)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "정산 정보가 없습니다."));

        List<TaxiSettlementPayment> payments =
                paymentRepository.findBySettlement(settlement);
        return TaxiSettlementResponse.of(settlement, payments);
    }

    // 납부 확인 토글
    @Transactional
    public void togglePayment(Long settlementId, Long userId, Long requesterId) {
        TaxiSettlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "정산 정보가 없습니다."));

        // 결제자 본인만 납부 확인 가능 (보안)
        if (!settlement.getPayer().getId().equals(requesterId)) {
            throw new BusinessException(("FORBIDDEN"), "결제자만 납부 확인을 처리할 수 있습니다.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."));

        TaxiSettlementPayment payment = paymentRepository
                .findBySettlementAndUser(settlement, user)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "납부 정보가 없습니다."));

        if (payment.getIsPaid()) {
            payment.markAsUnpaid();
        } else {
            payment.markAsPaid();
        }
    }

    // 정산 삭제
    @Transactional
    public void delete(Long settlementId, Long requesterId) {
        TaxiSettlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "정산 정보가 없습니다."
                ));

        // 결제자 본인만 삭제 가능 (보안)
        if (!settlement.getPayer().getId().equals(requesterId)) {
            throw new BusinessException(("FORBIDDEN"), "결제자만 정산을 삭제할 수 있습니다.");
        }

        paymentRepository.deleteBySettlement(settlement);
        settlementRepository.delete(settlement);
    }
}
