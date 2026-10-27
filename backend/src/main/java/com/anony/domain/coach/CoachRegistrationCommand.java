package com.anony.domain.coach;

import java.math.BigDecimal;
import java.util.List;

/**
 * Domain command containing all information required to register a coach.
 *
 * @param email coach email address
 * @param password raw password
 * @param firstName coach first name
 * @param lastName coach last name
 * @param photoUrl coach photo URL
 * @param gender coach self-declared gender
 * @param countryCode coach 2-letter ISO country code
 * @param timezone coach timezone identifier
 * @param biography coach biography
 * @param icfLevel ICF credential level (ACC, PCC, MCC, ACTC)
 * @param icfAcc whether coach possesses ACC credential
 * @param icfPcc whether coach possesses PCC credential
 * @param icfMcc whether coach possesses MCC credential
 * @param icfActc whether coach possesses ACTC credential
 * @param credentialDetails credential identifier or description
 * @param domainCodes coaching domain codes
 * @param hourlyRate optional hourly rate
 */
public record CoachRegistrationCommand(
    String email,
    String password,
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
    List<String> domainCodes,
    BigDecimal hourlyRate) {

  /**
   * Convenience constructor without extended profile fields.
   *
   * @param email coach email address
   * @param password raw password
   * @param firstName coach first name
   * @param lastName coach last name
   * @param icfLevel primary ICF level string
   * @param credentialDetails credential identifier or details
   * @param domainCodes domain specialization codes
   * @param timezone coach timezone
   * @param biography coach biography
   * @param hourlyRate coach hourly rate
   */
  public CoachRegistrationCommand(
      String email,
      String password,
      String firstName,
      String lastName,
      String icfLevel,
      String credentialDetails,
      List<String> domainCodes,
      String timezone,
      String biography,
      BigDecimal hourlyRate) {
    this(
        email,
        password,
        firstName,
        lastName,
        null,
        null,
        null,
        timezone,
        biography,
        icfLevel,
        null,
        null,
        null,
        null,
        credentialDetails,
        domainCodes,
        hourlyRate);
  }
}
