package com.smash.api.activity;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityPhoto;
import com.smash.domain.activity.ActivityPhotoRepository;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value; // application.yaml의 값을 필드에 주입 -> uploadDir, baseUrl 값을 미리 정해놓은 yaml에서 가져올 때 사용
import org.springframework.http.HttpHeaders; // HTTP 응답 헤더를 설정할 때 사용
import org.springframework.http.MediaType; // HTTP 미디어 타입 상수 모음 -> 파일 확장자로 Content-Type을 못 찾을 때 기본값으로 IMAGE_JPEG_VALUE 사용
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile; // 클라이언트가 업로드한 파일을 받는 인터페이스 -> Flutter가 올린 이미지 파일ㅇ르 받을 때 사용

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path; // 파일 / 디렉토리 경로를 표현하는 객체  -> String을 사용할 수도 있지만 String 경로보다 안전하고 OS 독립적
import java.nio.file.Paths; // Path 객체를 생성하는 유틸리티 클래스
import java.util.List;
import java.util.UUID; // 전 세계적으로 유일한 랜덤 문자열 생성 -> 여기서는 사진 파일명 중복 방지를 위해 사용

@Service
@RequiredArgsConstructor
public class ActivityPhotoService {

    private final ActivityPhotoRepository photoRepository;
    private final ActivityRepository activityRepository;
    private final UserRepository userRepository;

    @Value("${app.upload-dir:/home/baki/smash-files/photos}")
    private String uploadDir;

    @Value("${app.base-url:https://baki.tailbdb322.ts.net/api/v1}")
    private String baseUrl;

    // 사진 업로드
    @Transactional
    public List<ActivityPhotoResponse> upload(
            Long activityId, List<MultipartFile> files, Long userId) {

        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 활동입니다."));

        User uploader = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 유저입니다."));

        // 활동별 디렉토리 생성
        Path activityDir = Paths.get(uploadDir, String.valueOf(activityId));
        try {
            Files.createDirectories(activityDir);
        } catch (IOException e) {
            throw new BusinessException("FILE_ERROR", "디렉토리 생성에 실패했습니다.");
        }

        // 파일 저장
        for (MultipartFile file : files) {
            String ext = getExtension(file.getOriginalFilename());
            String fileName = UUID.randomUUID() + ext;
            Path filePath = activityDir.resolve(fileName);

            // 매직 바이트 검증 (보안)
            if (!isValidImage(file)) {
                throw new BusinessException("INVALID_FILE", "이미지 파일만 업로드 할 수 있습니다.");
            }

            try {
                file.transferTo(filePath);
            } catch (IOException e) {
                throw new BusinessException("FILE_ERROR", "파일 저장에 실패했습니다.");
            }

            photoRepository.save(ActivityPhoto.builder()
                    .activity(activity)
                    .uploadedBy(uploader)
                    .filePath(filePath.toString())
                    .build());
        }

        return getPhotos(activityId);
    }

    // 사진 목록 조회
    @Transactional(readOnly = true)
    public List<ActivityPhotoResponse> getPhotos(Long activityId) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 활동입니다."));

        return photoRepository.findByActivityOrderByCreatedAtAsc(activity)
                .stream()
                .map(photo -> ActivityPhotoResponse.of(photo, baseUrl))
                .toList();
    }

    // 사진 삭제
    @Transactional
    public void delete(Long photoId) {
        ActivityPhoto photo = photoRepository.findById(photoId)
                .orElseThrow(() -> new BusinessException(
                        "RESOURCE_NOT_FOUND", "존재하지 않는 사진입니다."));

        // 파일 삭제
        try {
            Files.deleteIfExists(Paths.get(photo.getFilePath()));
        } catch (IOException e) {
            throw new BusinessException("FILE_ERROR", "파일 삭제에 실패했습니다.");
        }

        photoRepository.delete(photo);
    }

    // 파일 서빙
    // 이 메서드를 만든 이유 : 사진 파일은 서버에만 존재 -> Flutter에서 직접 서버 경로로 접근 불가해서 (접근 권한 X) API를 통해서 데이터를 받아옴
    public ResponseEntity<byte[]> serveFile(String filename) {
        // 모든 활동 디렉토리에서 파일 검색
        try {
            Path uploadPath = Paths.get(uploadDir);
            Path filePath = Files.walk(uploadPath) // .walk(uploadPath) : uploadPath 경로 아래 모든 파일 순회
                    .filter(p -> p.getFileName().toString().equals(filename))
                    .findFirst()
                    .orElseThrow(() -> new BusinessException(
                            "RESOURCE_NOT_FOUND", "파일을 찾을 수 없습니다."));

            // byte로 받는 이유 : 이미지 파일은 byte로 저장되어있음 (0, 1) -> 파일을 byte 배열로 읽어와서 이미지로 디코딩
            byte[] bytes = Files.readAllBytes(filePath);
            // 파일 확장자를 보고 MIME 타입을 감지
            String filename2 = filePath.getFileName().toString().toLowerCase();
            String contentType;
            if (filename2.endsWith(".png")) {
                contentType = "image/png";
            } else if (filename2.endsWith(".gif")) {
                contentType = "image/gif";
            } else if (filename2.endsWith(".webp")) {
                contentType = "image/webp";
            } else {
                contentType = "image/jpeg";
            }
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_TYPE, contentType)
                    .body(bytes);

        } catch (IOException e) {
            throw new BusinessException("FILE_ERROR", "파일을 읽을 수 없습니다.");
        }
    }
    /*
        Flutter: Image.network("https://.../files/photos/a3f8c2d1.jpg")
            ↓
        서버: GET /files/photos/a3f8c2d1.jpg 요청 수신
            ↓
        Files.walk()로 파일 찾기
            ↓
        Files.readAllBytes()로 파일을 byte[]로 읽기
            ↓
        ResponseEntity에 byte[] + Content-Type 헤더 담아서 반환
            ↓
        Flutter: byte[]를 이미지로 디코딩해서 화면에 표시
     */

    // 확장자 추출
    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return ".jpg";
        return filename.substring(filename.lastIndexOf("."));
    }

    private boolean isValidImage(MultipartFile file) { // 매직 바이트로 사진 파일만 걸러내기
        try {
            byte[] bytes = file.getBytes();
            if (bytes.length < 4) return false;

            // JPEG : FF D8 FF
            if (bytes[0] == (byte) 0xFF && bytes[1] == (byte) 0xD8 && bytes[2] == (byte) 0xFF) {
                return true;
            }

            // PNG : 89 50 4E 47
            if (bytes[0] == (byte) 0x89 && bytes[1] == (byte) 0x50
                    && bytes[2] == (byte) 0x4E && bytes[3] == (byte) 0x47) {
                return true;
            }
            // GIF: 47 49 46 38
            if (bytes[0] == (byte) 0x47 && bytes[1] == (byte) 0x49
                    && bytes[2] == (byte) 0x46 && bytes[3] == (byte) 0x38) {
                return true;
            }
            // WEBP: 52 49 46 46 ... 57 45 42 50
            if (bytes[0] == (byte) 0x52 && bytes[1] == (byte) 0x49
                    && bytes[2] == (byte) 0x46 && bytes[3] == (byte) 0x46
                    && bytes.length >= 12
                    && bytes[8] == (byte) 0x57 && bytes[9] == (byte) 0x45
                    && bytes[10] == (byte) 0x42 && bytes[11] == (byte) 0x50) {
                return true;
            }
            return false;

        } catch (IOException e) {
            return false;
        }
    }
}