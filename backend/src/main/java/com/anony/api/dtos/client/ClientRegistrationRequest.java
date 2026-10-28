package com.anony.api.dtos.client;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

/**
 * Data transfer object for unified client and coach registration request payloads.
 *
 * @param email user email address
 * @param password account password
 * @param firstName optional first name (required for coaches)
 * @param lastName optional last name (required for coaches)
 * @param alias optional anonymous alias for clients
 * @param role optional role discriminator (CLIENT or COACH)
 * @param photoUrl optional coach photo URL
 * @param gender optional coach gender
 * @param countryCode optional coach 2-letter ISO country code
 * @param timezone optional coach timezone identifier
 * @param biography optional coach biography
 * @param icfLevel optional primary ICF credential level (ACC, PCC, MCC, ACTC)
 * @param icfAcc whether coach possesses ACC credential
 * @param icfPcc whether coach possesses PCC credential
 * @param icfMcc whether coach possesses MCC credential
 * @param icfActc whether coach possesses ACTC credential
 * @param credentialDetails optional credential identifier or details
 * @param domainCodes optional coaching domain codes
 * @param hourlyRate optional coach hourly rate
 */
public record ClientRegistrationRequest(
    @NotBlank(message = "Email is required") @Email(message = "Email format is invalid")
        String email,
    @NotBlank(message = "Password is required")
        @Size(min = 9, max = 32, message = "Password must be between 9 and 32 characters")
        String password,
    String firstName,
    String lastName,
    String alias,
    String role,
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
   * Convenience constructor for client-only registration payloads.
   *
   * @param email client email address
   * @param password account password
   * @param firstName optional client first name
   * @param lastName optional client last name
   * @param alias optional anonymous alias
   */
  public ClientRegistrationRequest(
      String email, String password, String firstName, String lastName, String alias) {
    this(
        email,
        password,
        firstName,
        lastName,
        alias,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null);
  }
}
