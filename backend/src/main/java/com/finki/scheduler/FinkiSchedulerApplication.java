package com.finki.scheduler;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class FinkiSchedulerApplication {
    public static void main(String[] args) {
        SpringApplication.run(FinkiSchedulerApplication.class, args);
    }
}
