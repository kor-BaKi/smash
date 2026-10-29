package com.smash;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.TimeZone;

@SpringBootApplication
@EnableScheduling // Spring에게 "이 앱에서 스케줄러를 쓴다"라고 알림 이게 없으면 @Schedule 동작 안함
public class SmashApplication {

	public static void main(String[] args) {
		// 서버 OS 시간대와 무관하게 KST로 고정 (투표 마감 판정, 스케줄러가 LocalDate/LocalTime.now() 사용)
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul"));
		SpringApplication.run(SmashApplication.class, args);
	}

}
