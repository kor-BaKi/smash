package com.smash.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

//    Spring Boot 서버에서 FCM으로 푸시 알림을 보내려면
//    Firebase Admin SDK를 초기화해야 합니다.
//
//    Firebase Admin SDK는 서버에서 Firebase 서비스를
//    사용할 수 있게 해주는 라이브러리입니다.
//    초기화 없이는 FCM 메시지를 보낼 수 없습니다.

@Configuration
public class FcmConfig {

    @PostConstruct // Spring이 이 Bean을 생성한 직후 자동으로 이 메서드를 실행
    public void initialize() throws IOException {

        InputStream serviceAccount =
                getClass().getClassLoader().getResourceAsStream("firebase-service-account.json");
//        아까 resources 폴더에 넣은 JSON 파일을 읽어옵니다.
//        이 JSON 파일 안에는:
//          - Firebase 프로젝트 ID
//          - 비공개 키
//          - 클라이언트 이메일
//        등이 들어 있습니다.
//
//        이것으로 서버가 Firebase에 인증합니다.
//        (구글에게 "나는 smash 프로젝트 서버야"라고 증명)

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build();
        // JSON 파일로 Google 인증 정보를 만들고
        // Firebase 옵션에 설정합니다.

        if (FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(options);
        }
        // FirebaseApp이 이미 초기화됐는지 확인합니다.
        // 서버 재시작 없이 핫 리로드 등으로 중복 초기화가
        // 발생할 수 있어서 방어 코드로 넣었습니다.
        //
        // 비어있을 때만 초기화 → 중복 초기화 방지
    }
}

// [전체 흐름]
// 서버 시작
//  → Spring이 FcmConfig Bean 생성
//  → @PostConstruct로 initialize() 자동 실행
//  → firebase-service-account.json 파일 읽기
//  → Google 인증 정보 생성
//  → Firebase Admin SDK 초기화 완료
//  → 이제 서버에서 FCM 메시지 전송 가능