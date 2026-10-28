package com.anony.domain.coach;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CoachAvailabilitySchedulerTest {

  @Mock
  private CoachService coachService;

  private CoachAvailabilityScheduler scheduler;

  @BeforeEach
  void setUp() {
    scheduler = new CoachAvailabilityScheduler(coachService);
  }

  @Test
  @DisplayName("generateAvailabilitiesOnStartup should trigger 30-day availability generation")
  void testGenerateAvailabilitiesOnStartup() {
    when(coachService.generateUpcomingAvailabilitiesForAllCoaches()).thenReturn(180);

    scheduler.generateAvailabilitiesOnStartup();

    verify(coachService).generateUpcomingAvailabilitiesForAllCoaches();
  }

  @Test
  @DisplayName("generateAvailabilitiesDaily should trigger 30-day availability generation via cron")
  void testGenerateAvailabilitiesDaily() {
    when(coachService.generateUpcomingAvailabilitiesForAllCoaches()).thenReturn(24);

    scheduler.generateAvailabilitiesDaily();

    verify(coachService).generateUpcomingAvailabilitiesForAllCoaches();
  }
}
