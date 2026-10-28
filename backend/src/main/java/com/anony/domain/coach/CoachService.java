package com.anony.domain.coach;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Service interface for coach onboarding, profile retrieval, credential management,
 * and 30-day rolling availability generation and discovery.
 */
public interface CoachService {

  /**
   * Registers a new coach user and associated coach profile.
   * Default verification status is set to false.
   *
   * @param coachRegistrationCommand registration details
   * @return created coach profile details
   */
  CoachProfileDetails registerCoach(CoachRegistrationCommand coachRegistrationCommand);

  /**
   * Updates an existing coach profile for the given user identifier.
   *
   * @param userId unique user identifier
   * @param coachUpdateCommand updated profile details
   * @return updated coach profile details
   */
  CoachProfileDetails updateCoachProfile(UUID userId, CoachUpdateCommand coachUpdateCommand);

  /**
   * Retrieves the coach profile associated with the given user identifier.
   *
   * @param userId unique user identifier
   * @return coach profile details
   */
  CoachProfileDetails getCoachProfileByUserId(UUID userId);

  /**
   * Generates concrete availability slots for all coaches for the next 30 days starting today,
   * slicing each coach's weekly availability windows into 30-minute or 60-minute UTC slots and
   * satisfying the mandatory 1-hour monthly free session pledge.
   *
   * @return total number of newly created availability slots
   */
  int generateUpcomingAvailabilitiesForAllCoaches();

  /**
   * Retrieves unbooked availability slots for a specific coach within a UTC date range.
   *
   * @param coachId unique coach identifier
   * @param from optional inclusive UTC start timestamp
   * @param to optional inclusive UTC end timestamp
   * @return list of unbooked availability slot details ordered by start timestamp
   */
  List<CoachAvailabilitySlotDetails> getCoachAvailabilities(
      UUID coachId, Instant from, Instant to);
}
