// ApplicationAnswerRepository.java
package com.smash.domain.application;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ApplicationAnswerRepository extends JpaRepository<ApplicationAnswer, Long> {
    List<ApplicationAnswer> findByApplicationOrderByQuestionOrderIndex(Application application); // 지원서의 답변을 질문 순서대로 조회
    void deleteByApplication(Application application);
}