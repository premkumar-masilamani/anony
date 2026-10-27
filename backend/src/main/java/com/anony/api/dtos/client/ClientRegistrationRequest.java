package com.anony.api.dtos.client;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Data transfer object for client registration request payloads.
 *
 * @param email client email address
 * @param password account password
 * @param firstName optional client first name
 * @param lastName optional client last name
 * @param alias optional anonymous alias
 */
public record ClientRegistrationRequest(
    @NotBlank(message = "Email is required") @Email(message = "Email format is invalid")
        String email,
    @NotBlank(message = "Password is required")
        @Size(min = 9, max = 32, message = "Password must be between 9 and 32 characters")
        String password,
    String firstName,
    String lastName,
    String alias) {}
