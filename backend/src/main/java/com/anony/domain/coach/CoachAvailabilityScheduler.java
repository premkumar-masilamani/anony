package com.anony.domain.coach;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Spring Boot scheduler that generates 30-day rolling availability slots for all coaches
 * automatically on application startup and daily at midnight UTC.
 */
@Component
public class CoachAvailabilityScheduler {

  private static final Logger logger = LoggerFactory.getLogger(CoachAvailabilityScheduler.class);

  private final CoachService coachService;

  /**
   * Constructs the availability scheduler with the required coach service.
   *
   * @param coachService service managing coach availability generation
   */
  public CoachAvailabilityScheduler(CoachService coachService) {
    this.coachService = coachService;
  }

  /**
   * Generates upcoming 30-day availability slots for all coaches immediately when the
   * application context is ready.
   */
  @EventListener(ApplicationReadyEvent.class)
  public void generateAvailabilitiesOnStartup() {
    logger.info(
        "Triggering startup coach availability generation for the next 30 days...");
    int createdSlots = coachService.generateUpcomingAvailabilitiesForAllCoaches();
    logger.info(
        "Generated {} coach availability slots for the next 30 days on startup.", createdSlots);
  }

  /**
   * Generates upcoming 30-day availability slots for all coaches every day at midnight UTC.
   */
  @Scheduled(cron = "0 0 0 * * *")
  public void generateAvailabilitiesDaily() {
    logger.info(
        "Triggering daily cron coach availability generation for the next 30 days...");
    int createdSlots = coachService.generateUpcomingAvailabilitiesForAllCoaches();
    logger.info(
        "Generated {} coach availability slots for the next 30 days via daily cron.",
        createdSlots);
  }
}
