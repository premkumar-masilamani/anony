package com.anony;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableAsync
public class AnonyApp {

  private static final Logger logger = LoggerFactory.getLogger(AnonyApp.class);

  public static void main(String[] args) {
    logger.info("Starting Anony Application...");
    SpringApplication.run(AnonyApp.class, args);
    logger.info("Anony Application started successfully.");
  }
}
