package com.anony.domain.coach;

import java.math.BigDecimal;
import java.util.List;

/**
 * Domain command containing updated coach profile and credential details.
 *
 * @param firstName coach first name
 * @param lastName coach last name
 * @param photoUrl coach photo URL
 * @param gender coach self-declared gender
 * @param countryCode coach 2-letter ISO country code
 * @param timezone coach timezone identifier
 * @param biography coach biography
 * @param icfLevel primary ICF level string
 * @param icfAcc whether coach possesses ACC credential
 * @param icfPcc whether coach possesses PCC credential
 * @param icfMcc whether coach possesses MCC credential
 * @param icfActc whether coach possesses ACTC credential
 * @param credentialDetails credential identifier or details
 * @param domainCodes domain specialization codes
 * @param hourlyRate coach hourly rate
 */
public record CoachUpdateCommand(
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
    BigDecimal hourlyRate) {}
