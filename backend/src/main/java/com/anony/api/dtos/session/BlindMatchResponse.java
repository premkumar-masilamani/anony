package com.anony.api.dtos.session;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.UUID;

/**
 * Data transfer object returned upon successful atomic blind match scheduling.
 *
 * @param sessionId unique session identifier
 * @param coachAlias procedural alias of matched coach
 * @param coachIcfLevel coach verified ICF credential level
 * @param topic session topic or struggle prompt
 * @param scheduledTime scheduled start time in UTC
 * @param status booking status (CONFIRMED)
 * @param isProBono whether session is a free pro-bono pledge
 * @param freeSessionsUsed number of pro-bono sessions utilized
 * @param maxFreeSessions platform lifetime allowance cap
 * @param nextFreeSessionAvailableAt timestamp when the client becomes eligible for next pro-bono session
 */
public record BlindMatchResponse(
    @JsonProperty("session_id")
    UUID sessionId,

    @JsonProperty("coach_alias")
    String coachAlias,

    @JsonProperty("coach_icf_level")
    String coachIcfLevel,

    @JsonProperty("topic")
    String topic,

    @JsonProperty("scheduled_time")
    Instant scheduledTime,

    @JsonProperty("status")
    String status,

    @JsonProperty("is_pro_bono")
    boolean isProBono,

    @JsonProperty("free_sessions_used")
    int freeSessionsUsed,

    @JsonProperty("max_free_sessions")
    int maxFreeSessions,

    @JsonProperty("next_free_session_available_at")
    Instant nextFreeSessionAvailableAt) {}
