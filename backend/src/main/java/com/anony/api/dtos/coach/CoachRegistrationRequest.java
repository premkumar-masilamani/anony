package com.anony.api.dtos.coach;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

/**
 * Data transfer object for coach registration request payloads.
 *
 * @param email coach email address
 * @param password account password
 * @param firstName coach first name
 * @param lastName coach last name
 * @param icfLevel ICF credential level (ACC, PCC, MCC, ACTC)
 * @param credentialDetails credential identifier or details
 * @param domainCodes coaching domain codes
 * @param timezone coach timezone identifier
 * @param biography coach biography
 * @param hourlyRate optional hourly rate
 */
public record CoachRegistrationRequest(
    @NotBlank(message = "Email is required") @Email(message = "Email format is invalid")
        String email,
    @NotBlank(message = "Password is required")
        @Size(min = 9, max = 32, message = "Password must be between 9 and 32 characters")
        String password,
    @NotBlank(message = "First name is required") String firstName,
    @NotBlank(message = "Last name is required") String lastName,
    @NotBlank(message = "ICF level is required") String icfLevel,
    String credentialDetails,
    @NotEmpty(message = "At least one domain tag must be provided") List<String> domainCodes,
    String timezone,
    String biography,
    BigDecimal hourlyRate) {}
