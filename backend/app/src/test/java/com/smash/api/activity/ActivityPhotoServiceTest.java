package com.smash.api.activity;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityPhoto;
import com.smash.domain.activity.ActivityPhotoRepository;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ActivityPhotoServiceTest {

    @Mock ActivityPhotoRepository photoRepository;
    @Mock ActivityRepository activityRepository;
    @Mock UserRepository userRepository;

    @InjectMocks ActivityPhotoService photoService;

    @TempDir Path tempDir;

    private static final byte[] JPEG = {
            (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 0, 0, 0, 0, 0, 0, 0};
    private static final byte[] NOT_IMAGE = "<html><script>alert(1)</script></html>".getBytes();

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(photoService, "uploadDir", tempDir.toString());
        Activity activity = mock(Activity.class);
        User user = mock(User.class);
        given(activityRepository.findById(1L)).willReturn(Optional.of(activity));
        given(userRepository.findById(2L)).willReturn(Optional.of(user));
    }

    @Test
    @DisplayName("파일명이 .html이어도 이미지 내용이면 서버가 정한 .jpg 확장자로 저장된다")
    void upload_ignoresClientFilename() {
        MockMultipartFile file = new MockMultipartFile(
                "files", "evil.html", "image/jpeg", JPEG);

        photoService.upload(1L, List.of(file), 2L);

        ArgumentCaptor<ActivityPhoto> captor = ArgumentCaptor.forClass(ActivityPhoto.class);
        verify(photoRepository).save(captor.capture());
        assertThat(captor.getValue().getFilePath()).endsWith(".jpg");
        assertThat(captor.getValue().getFilePath()).doesNotContain("evil");
    }

    @Test
    @DisplayName("이미지가 아닌 내용은 확장자를 jpg로 위장해도 INVALID_FILE")
    void upload_nonImage_rejected() {
        MockMultipartFile file = new MockMultipartFile(
                "files", "photo.jpg", "image/jpeg", NOT_IMAGE);

        Throwable thrown = catchThrowable(
                () -> photoService.upload(1L, List.of(file), 2L));

        assertThat(thrown).isInstanceOf(BusinessException.class);
        assertThat(((BusinessException) thrown).getCode()).isEqualTo("INVALID_FILE");
        verify(photoRepository, never()).save(any());
    }

    @Test
    @DisplayName("여러 장 중 하나라도 잘못되면 어떤 파일도 저장되지 않는다")
    void upload_oneInvalid_nothingSaved() {
        MockMultipartFile valid = new MockMultipartFile("files", "a.jpg", "image/jpeg", JPEG);
        MockMultipartFile invalid = new MockMultipartFile("files", "b.jpg", "image/jpeg", NOT_IMAGE);

        Throwable thrown = catchThrowable(
                () -> photoService.upload(1L, List.of(valid, invalid), 2L));

        assertThat(thrown).isInstanceOf(BusinessException.class);
        verify(photoRepository, never()).save(any());
        // 검증을 먼저 하므로 활동 디렉토리조차 만들어지지 않음
        assertThat(Files.exists(tempDir.resolve("1"))).isFalse();
    }
}