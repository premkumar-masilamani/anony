package com.anony.domain.coach;

import java.util.UUID;

/**
 * Service interface managing coach registration, profile lookups, and verification retrieval.
 */
public interface CoachService {

  /**
   * Registers a new coach profile defaulting verification status to false.
   *
   * @param coachRegistrationCommand registration command with credentials and domains
   * @return newly created coach profile details
   */
  CoachProfileDetails registerCoach(CoachRegistrationCommand coachRegistrationCommand);

  /**
   * Retrieves current coach profile details by user identifier.
   *
   * @param userId user identifier
   * @return current coach profile details
   */
  CoachProfileDetails getCoachProfileByUserId(UUID userId);
}
