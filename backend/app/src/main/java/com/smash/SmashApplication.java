package com.smash;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling // Spring에게 "이 앱에서 스케줄러를 쓴다"라고 알림 이게 없으면 @Schedule 동작 안함
public class SmashApplication {

	public static void main(String[] args) {
		SpringApplication.run(SmashApplication.class, args);
	}

}
