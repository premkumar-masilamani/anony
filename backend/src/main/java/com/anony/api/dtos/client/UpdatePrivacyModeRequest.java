package com.anony.api.dtos.client;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

/**
 * Data transfer object for updating a client's anonymity mode.
 *
 * @param isAnonymousMode whether anonymous blind matching mode is active
 */
public record UpdatePrivacyModeRequest(
    @NotNull(message = "isAnonymousMode is required")
    @JsonProperty("is_anonymous_mode")
    Boolean isAnonymousMode) {}
