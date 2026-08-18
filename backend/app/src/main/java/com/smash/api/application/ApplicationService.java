package com.smash.api.application;

import com.smash.common.exception.BusinessException;
import com.smash.domain.application.*;
import com.smash.domain.availability.MemberAvailability;
import com.smash.domain.availability.MemberAvailabilityRepository;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.*;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.Map;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApplicationService {

    private final ApplicationFormRepository formRepository;
    private final FormQuestionRepository questionRepository;
    private final ApplicationRepository applicationRepository;
    private final ApplicationAnswerRepository answerRepository;
    private final UserRepository userRepository;
    private final MemberAvailabilityRepository availabilityRepository;
    private final GroupRepository groupRepository;

    // 폼 관리 (ADMIN)

    // 폼 생성
    @Transactional
    public ApplicationFormResponse createForm(ApplicationFormRequest request) {
        ApplicationForm form = formRepository.save(
                ApplicationForm.builder()
                        .isActive(false).startDate(request.getStartDate()).endDate(request.getEndDate()).build()
        );

        return ApplicationFormResponse.of(form, List.of()); // List.of() = 빈 리스트 반환
    }

    // 현재 폼 조회
    @Transactional(readOnly = true)
    public ApplicationFormResponse getForm() {
        ApplicationForm form = getLatestForm();
        List<FormQuestion> questions = questionRepository.findByFormOrderByOrderIndex(form);
        return ApplicationFormResponse.of(form, questions);
    }

    // 폼 활성 / 비활성 토글
    @Transactional
    public void toggleForm(boolean isActive) {
        ApplicationForm form = getLatestForm();
        form.toggle(isActive);
    }

    // 폼 기간 수정
    @Transactional
    public void updateFormPeriod(ApplicationFormRequest request) {
        ApplicationForm form = getLatestForm();
        form.updatePeriod(request.getStartDate(), request.getEndDate());
    }

    // 질문 관리 (ADMIN)

    // 질문 추가
    @Transactional
    public ApplicationFormResponse addQuestion(FormQuestionRequest request) {
        ApplicationForm form = getLatestForm();
        List<FormQuestion> existing = questionRepository.findByFormOrderByOrderIndex(form);

        questionRepository.save(
                FormQuestion.builder()
                        .form(form)
                        .content(request.getContent())
                        .questionType(QuestionType.valueOf(request.getQuestionType()))
                        .isRequired(request.isRequired())
                        .orderIndex(existing.size()) // 맨 마지막에 추가
                        .options(request.getOptions())
                        .build()
        );

        List<FormQuestion> updated = questionRepository.findByFormOrderByOrderIndex(form);
        return ApplicationFormResponse.of(form, updated);
    }

    // 질문 삭제
    @Transactional
    public ApplicationFormResponse deleteQuestion(Long questionId) {
        FormQuestion question = questionRepository.findById(questionId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 질문입니다."
                ));
        questionRepository.delete(question);

        ApplicationForm form = question.getForm();
        // 순서 재정렬
        List<FormQuestion> remaining = questionRepository.findByFormOrderByOrderIndex(form);
        for (int i = 0; i < remaining.size(); i++) {
            remaining.get(i).update(
                    remaining.get(i).getContent(),
                    remaining.get(i).isRequired(),
                    i
            );
        }

        return ApplicationFormResponse.of(form, remaining);
    }

    // 질문 순서 변경
    @Transactional
    public ApplicationFormResponse reorderQuestions(List<Long> questionIds) {
        for (int i = 0; i < questionIds.size(); i++) {
            FormQuestion question = questionRepository.findById(questionIds.get(i))
                    .orElseThrow(() -> new BusinessException(
                            "RESOURCE_NOT_FOUND", "존재하지 않는 질문입니다."
                    ));
            question.update(question.getContent(), question.isRequired(), i);
        }
        ApplicationForm form = getLatestForm();
        List<FormQuestion> updated = questionRepository.findByFormOrderByOrderIndex(form);
        return ApplicationFormResponse.of(form, updated);
    }

    // 지원서 (웹 폼)

    // 현재 활성 폼 조회 (웹 폼용)
    @Transactional
    public ApplicationFormResponse getActiveForm() {
        ApplicationForm form = getLatestForm();
        if (!form.isActive()) {
            throw new BusinessException("FORM_NOT_ACTIVE", "현재 지원 기간이 아닙니다.");
        }
        List<FormQuestion> questions = questionRepository.findByFormOrderByOrderIndex(form);
        return ApplicationFormResponse.of(form, questions);
    }

    // 지원서 제출
    @Transactional
    public void submit(ApplicationSubmitRequest request) {
        ApplicationForm form = getLatestForm();

        if (!form.isActive()) {
            throw new BusinessException("FORM_NOT_ACTIVE", "현재 지원 기간이 아닙니다.");
        }

        // 중복 지원 방지
        if (applicationRepository.existsByFormAndStudentNo(form, request.getStudentNo())) {
            throw new BusinessException("ALREADY_APPLIED", "이미 지원한 학번입니다.");
        }

        // 희망 활동 시간 저장
        String availabilities = request.getAvailabilities().stream()
                .map(a -> a.getDayOfWeek().name() + ":" + a.getTimeSlot().name())
                .collect(Collectors.joining(","));

        // 지원서 저장
        Application application = applicationRepository.save(
                Application.builder()
                        .form(form)
                        .name(request.getName())
                        .studentNo(request.getStudentNo())
                        .department(request.getDepartment())
                        .phone(request.getPhone())
                        .availabilities(availabilities)
                        .build()
        );

        // 답변 저장
        if (request.getAnswer() != null) {
            for (ApplicationSubmitRequest.AnswerRequest answerRequest : request.getAnswer()) {
                FormQuestion question = questionRepository.findById(answerRequest.getQuestionId())
                        .orElseThrow(() -> new BusinessException("RESOURCE_NOT_FOUND", "존재하지 않는 질문입니다."));
                answerRepository.save(
                        ApplicationAnswer.builder()
                                .application(application)
                                .question(question)
                                .answer(answerRequest.getAnswer())
                                .build()
                );
            }
        }
    }

    // 지원서 관리 (ADMIN)

    // 지원서 목록 조회
    @Transactional
    public List<ApplicationResponse> getApplications() {
        ApplicationForm form = getLatestForm();
        return applicationRepository.findByFormOrderByCreatedAtDesc(form)
                .stream()
                .map(ApplicationResponse::ofSimple)
                .toList();
    }

    // 지원서 상세 조회
    @Transactional
    public ApplicationResponse getApplication(Long applicationId) {
        Application application = getApplicationById(applicationId);
        List<ApplicationAnswer> answers = answerRepository.findByApplicationOrderByQuestionOrderIndex(application);
        return ApplicationResponse.of(application, answers);
    }

    // 합격 처리
    @Transactional
    public void accept(Long applicationId) {
        Application application = getApplicationById(applicationId);

        // 중복 확인
        if (userRepository.existsByStudentNo(application.getStudentNo())) {
            throw new BusinessException("ALREADY_EXISTS", "이미 등록된 학번입니다.");
        }

        application.accept();

        // users 테이블 자동 등록 (PENDING)
        User newUser = userRepository.save(
                User.builder()
                        .name(application.getName())
                        .studentNo(application.getStudentNo())
                        .department(application.getDepartment())
                        .phone(application.getPhone())
                        .role(Role.MEMBER)
                        .status(Status.PENDING)
                        .build()
        );

        // member_availability 자동 등록
        String[] pairs = application.getAvailabilities().split(",");
        for (String pair : pairs) {
            String[] parts = pair.split(":");
            DayOfWeek dayOfWeek = DayOfWeek.valueOf(parts[0]);
            TimeSlot timeSlot = TimeSlot.valueOf(parts[1]);

            Group group = groupRepository
                    .findByDayOfWeekAndTimeSlot(dayOfWeek, timeSlot)
                    .orElseThrow(() -> new BusinessException(
                            "RESOURCE_NOT_FOUND", "해당 조가 존재하지 않습니다."));

            availabilityRepository.save(
                    MemberAvailability.builder()
                            .user(newUser)
                            .group(group)
                            .build()
            );
        }
    }

    // 불합격 처리
    @Transactional
    public void reject(Long applicationId) {
        Application application = getApplicationById(applicationId);
        application.reject();
    }

    // 메모 수정
    @Transactional
    public void updateMemo(Long applicationId, String memo) {
        Application application = getApplicationById(applicationId);
        application.updateMemo(memo);
    }

    private Application getApplicationById(Long applicationId) {
        return applicationRepository.findById(applicationId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 지원서입니다."
                ));
    }

    private ApplicationForm getLatestForm() {
        return formRepository.findTopByOrderByCreatedAtDesc()
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "지원 폼이 존재하지 않습니다."
                ));
    }

    // 엑셀 내보내기
    public byte[] exportToExcel() {
        ApplicationForm form = getLatestForm();
        List<Application> applications =
                applicationRepository.findByFormOrderByCreatedAtDesc(form);
        List<FormQuestion> questions =
                questionRepository.findByFormOrderByOrderIndex(form);

        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            XSSFSheet sheet = workbook.createSheet("지원서 목록");

            // 헤더 스타일
            XSSFCellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFillForegroundColor(new XSSFColor(new byte[]{(byte)61, (byte)123, (byte)245}, null));
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            XSSFFont headerFont = workbook.createFont();
            headerFont.setColor(IndexedColors.WHITE.getIndex());
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);

            // 헤더 행 생성
            Row headerRow = sheet.createRow(0);
            int col = 0;
            String[] fixedHeaders = {"이름", "학번", "학과", "전화번호", "희망 활동 시간", "상태", "지원일"};
            for (String header : fixedHeaders) {
                Cell cell = headerRow.createCell(col++);
                cell.setCellValue(header);
                cell.setCellStyle(headerStyle);
            }
            // 커스텀 질문 헤더
            for (FormQuestion q : questions) {
                Cell cell = headerRow.createCell(col++);
                cell.setCellValue(q.getContent());
                cell.setCellStyle(headerStyle);
            }

            // 데이터 행 생성
            int rowNum = 1;
            for (Application app : applications) {
                Row row = sheet.createRow(rowNum++);
                int c = 0;

                row.createCell(c++).setCellValue(app.getName());
                row.createCell(c++).setCellValue(app.getStudentNo());
                row.createCell(c++).setCellValue(app.getDepartment());
                row.createCell(c++).setCellValue(app.getPhone());
                row.createCell(c++).setCellValue(
                        formatAvailabilities(app.getAvailabilities()));
                row.createCell(c++).setCellValue(
                        formatStatus(app.getStatus().name()));
                row.createCell(c++).setCellValue(
                        app.getCreatedAt().toString().substring(0, 10));

                // 커스텀 질문 답변
                List<ApplicationAnswer> answers =
                        answerRepository.findByApplicationOrderByQuestionOrderIndex(app);
                Map<Long, String> answerMap = answers.stream()
                        .collect(Collectors.toMap(
                                a -> a.getQuestion().getId(),
                                ApplicationAnswer::getAnswer
                        ));
                for (FormQuestion q : questions) {
                    row.createCell(c++).setCellValue(
                            answerMap.getOrDefault(q.getId(), ""));
                }
            }

            // 열 너비 자동 조정
            for (int i = 0; i < col; i++) {
                sheet.autoSizeColumn(i);
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            workbook.write(out);
            return out.toByteArray();

        } catch (IOException e) {
            throw new BusinessException("SERVER_ERROR", "엑셀 파일 생성에 실패했습니다.");
        }
    }

    private String formatAvailabilities(String availabilities) {
        if (availabilities == null) return "";
        Map<String, String> dayMap = Map.of(
                "MON", "월", "TUE", "화", "WED", "수",
                "THU", "목", "FRI", "금"
        );
        Map<String, String> slotMap = Map.of(
                "SLOT_13_15", "1-3시",
                "SLOT_15_17", "3-5시"
        );
        return Arrays.stream(availabilities.split(","))
                .map(pair -> {
                    String[] parts = pair.split(":");
                    return dayMap.getOrDefault(parts[0], parts[0]) + " "
                            + slotMap.getOrDefault(parts[1], parts[1]);
                })
                .collect(Collectors.joining(", "));
    }

    private String formatStatus(String status) {
        return switch (status) {
            case "PENDING" -> "미처리";
            case "ACCEPTED" -> "합격";
            case "REJECTED" -> "불합격";
            default -> status;
        };
    }

}
