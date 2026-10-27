package com.anony.api.dtos.session;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Data transfer object returned on HTTP 409 Conflict when pro-bono quotas are exceeded.
 *
 * @param error top-level error identifier
 * @param reason specific quota violation reason (COOLDOWN_ACTIVE or LIFETIME_CAP_REACHED)
 * @param message calming explanatory message for the client
 * @param daysRemaining remaining days until next free session unlocks (0 if cap reached)
 * @param freeSessionsUsed number of pro-bono sessions completed so far
 * @param maxFreeSessions platform lifetime allowance cap
 * @param suggestedAction suggested action guidance (e.g. SWITCH_TO_REGULAR_MODE_FOR_PAID_BOOKINGS)
 */
public record QuotaExceededErrorResponse(
    @JsonProperty("error")
    String error,

    @JsonProperty("reason")
    String reason,

    @JsonProperty("message")
    String message,

    @JsonProperty("days_remaining")
    int daysRemaining,

    @JsonProperty("free_sessions_used")
    int freeSessionsUsed,

    @JsonProperty("max_free_sessions")
    int maxFreeSessions,

    @JsonProperty("suggested_action")
    String suggestedAction) {}
