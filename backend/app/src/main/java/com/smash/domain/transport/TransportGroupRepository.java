package com.smash.domain.transport;

import com.smash.domain.activity.Activity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransportGroupRepository extends JpaRepository<TransportGroup, Long> {
    List<TransportGroup> findByActivityOrderByGroupNumber(Activity activity); // 활동의 택시 그룹 목록을 그룹 번호 순으로 조회
    void deleteByActivity(Activity activity); // 활동의 모든 그룹 삭제 (배정 초기화 시 사용)
}


/*
    Activity (오늘 활동)
      └── TransportGroup (1호차)
            └── TransportMember (김동현)
            └── TransportMember (이서연)
            └── TransportMember (박민수)
      └── TransportGroup (2호차)
            └── TransportMember (최유진)
            └── TransportMember (한소희)
 */