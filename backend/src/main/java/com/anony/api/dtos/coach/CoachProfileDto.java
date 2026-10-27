package com.anony.api.dtos.coach;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Data transfer object representing a coach's full profile and verification state.
 *
 * @param coachId unique coach identifier
 * @param userId associated user identifier
 * @param email coach email address
 * @param firstName coach first name
 * @param lastName coach last name
 * @param photoUrl coach photo URL
 * @param gender coach self-declared gender
 * @param countryCode coach 2-letter ISO country code
 * @param timezone coach timezone
 * @param biography coach biography
 * @param icfLevel primary ICF level string
 * @param icfAcc whether coach holds ACC credential
 * @param icfPcc whether coach holds PCC credential
 * @param icfMcc whether coach holds MCC credential
 * @param icfActc whether coach holds ACTC credential
 * @param credentialDetails credential identifier or details
 * @param hourlyRate coach hourly rate
 * @param isVerified whether coach profile has been verified
 * @param isOnboarded whether coach has completed onboarding
 * @param domainCodes coaching domain specializations
 * @param createdAt timestamp when profile was created
 */
public record CoachProfileDto(
    UUID coachId,
    UUID userId,
    String email,
    String firstName,
    String lastName,
    String photoUrl,
    String gender,
    String countryCode,
    String timezone,
    String biography,
    String icfLevel,
    Boolean icfAcc,
    Boolean icfPcc,
    Boolean icfMcc,
    Boolean icfActc,
    String credentialDetails,
    BigDecimal hourlyRate,
    Boolean isVerified,
    Boolean isOnboarded,
    List<String> domainCodes,
    Instant createdAt) {

  /**
   * Convenience constructor without optional extended profile fields.
   *
   * @param coachId unique coach identifier
   * @param userId associated user identifier
   * @param email coach email address
   * @param firstName coach first name
   * @param lastName coach last name
   * @param timezone coach timezone
   * @param biography coach biography
   * @param icfLevel primary ICF level string
   * @param icfAcc whether coach holds ACC credential
   * @param icfPcc whether coach holds PCC credential
   * @param icfMcc whether coach holds MCC credential
   * @param icfActc whether coach holds ACTC credential
   * @param credentialDetails credential identifier or details
   * @param isVerified whether coach profile has been verified
   * @param isOnboarded whether coach has completed onboarding
   * @param domainCodes coaching domain specializations
   * @param createdAt timestamp when profile was created
   */
  public CoachProfileDto(
      UUID coachId,
      UUID userId,
      String email,
      String firstName,
      String lastName,
      String timezone,
      String biography,
      String icfLevel,
      Boolean icfAcc,
      Boolean icfPcc,
      Boolean icfMcc,
      Boolean icfActc,
      String credentialDetails,
      Boolean isVerified,
      Boolean isOnboarded,
      List<String> domainCodes,
      Instant createdAt) {
    this(
        coachId,
        userId,
        email,
        firstName,
        lastName,
        null,
        null,
        null,
        timezone,
        biography,
        icfLevel,
        icfAcc,
        icfPcc,
        icfMcc,
        icfActc,
        credentialDetails,
        null,
        isVerified,
        isOnboarded,
        domainCodes,
        createdAt);
  }
}
