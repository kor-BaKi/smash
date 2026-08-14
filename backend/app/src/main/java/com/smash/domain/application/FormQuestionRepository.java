// FormQuestionRepository.java
package com.smash.domain.application;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FormQuestionRepository extends JpaRepository<FormQuestion, Long> {
    List<FormQuestion> findByFormOrderByOrderIndex(ApplicationForm form); // 폼의 질문을 순서대로 조회
    void deleteByForm(ApplicationForm form);
}