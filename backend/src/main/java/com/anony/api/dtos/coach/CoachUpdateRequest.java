package com.anony.api.dtos.coach;

import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.util.List;

/**
 * Data transfer object for coach profile update request payloads.
 *
 * @param firstName coach first name
 * @param lastName coach last name
 * @param photoUrl coach photo URL
 * @param gender coach self-declared gender
 * @param countryCode coach 2-letter ISO country code
 * @param timezone coach timezone identifier
 * @param biography coach biography
 * @param icfLevel primary ICF credential level
 * @param icfAcc whether coach possesses ACC credential
 * @param icfPcc whether coach possesses PCC credential
 * @param icfMcc whether coach possesses MCC credential
 * @param icfActc whether coach possesses ACTC credential
 * @param credentialDetails credential identifier or details
 * @param domainCodes coaching domain codes
 * @param hourlyRate optional hourly rate
 */
public record CoachUpdateRequest(
    @NotBlank(message = "First name is required") String firstName,
    @NotBlank(message = "Last name is required") String lastName,
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
