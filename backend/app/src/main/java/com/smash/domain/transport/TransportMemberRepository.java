package com.smash.domain.transport;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransportMemberRepository extends JpaRepository<TransportMember, Long> {
    List<TransportMember> findByTransportGroup(TransportGroup transportGroup); // 특정 그룹의 탑승자 목록 조회
    void deleteByTransportGroup(TransportGroup transportGroup); // 특정 그룹의 탑승자 전체 삭제

}