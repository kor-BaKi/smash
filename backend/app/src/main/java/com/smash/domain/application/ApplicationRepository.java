// ApplicationRepository.java
package com.smash.domain.application;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findByFormOrderByCreatedAtDesc(ApplicationForm form);
    boolean existsByFormAndStudentNo(ApplicationForm form, String studentNo); // 중복 지원 방지 (같음 폼에 같은 학번)
}