package com.anony.api.dtos.session;

import com.anony.domain.session.BookingType;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.UUID;

/**
 * Unified data transfer object returned upon successful atomic session booking
 * (either free blind match or direct paid slot booking).
 *
 * @param sessionId unique session identifier
 * @param slotId locked bookable slot identifier
 * @param coachId matched or selected coach identifier
 * @param coachAlias procedural or display alias of the coach
 * @param coachIcfLevel coach verified ICF credential level
 * @param domainCode resolved coaching domain code
 * @param topic session topic or struggle essence
 * @param scheduledTime scheduled start time in UTC
 * @param endTime scheduled end time in UTC
 * @param bookingType resolved booking mode ({@code FREE} or {@code PAID})
 * @param status booking status ({@code CONFIRMED})
 * @param awaitingCheckout whether the session is awaiting payment checkout
 * @param isProBono whether session is a free pro-bono pledge
 * @param freeSessionsUsed number of pro-bono sessions utilized by the client
 * @param maxFreeSessions platform lifetime allowance cap
 * @param nextFreeSessionAvailableAt timestamp when the client becomes eligible for next pro-bono session
 */
public record BlindMatchResponse(
    @JsonProperty("session_id")
    UUID sessionId,

    @JsonProperty("slot_id")
    UUID slotId,

    @JsonProperty("coach_id")
    UUID coachId,

    @JsonProperty("coach_alias")
    String coachAlias,

    @JsonProperty("coach_icf_level")
    String coachIcfLevel,

    @JsonProperty("domain_code")
    String domainCode,

    @JsonProperty("topic")
    String topic,

    @JsonProperty("scheduled_time")
    Instant scheduledTime,

    @JsonProperty("end_time")
    Instant endTime,

    @JsonProperty("booking_type")
    BookingType bookingType,

    @JsonProperty("status")
    String status,

    @JsonProperty("awaiting_checkout")
    boolean awaitingCheckout,

    @JsonProperty("is_pro_bono")
    boolean isProBono,

    @JsonProperty("free_sessions_used")
    int freeSessionsUsed,

    @JsonProperty("max_free_sessions")
    int maxFreeSessions,

    @JsonProperty("next_free_session_available_at")
    Instant nextFreeSessionAvailableAt) {}
