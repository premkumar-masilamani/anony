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
 * @param icfLevel ICF credential level (ACC, PCC, MCC, ACTC)
 * @param credentialDetails credential identifier or description
 * @param domainCodes coaching domain codes
 * @param timezone coach timezone identifier
 * @param biography coach biography
 * @param hourlyRate optional hourly rate
 */
public record CoachRegistrationCommand(
    String email,
    String password,
    String firstName,
    String lastName,
    String icfLevel,
    String credentialDetails,
    List<String> domainCodes,
    String timezone,
    String biography,
    BigDecimal hourlyRate) {}
