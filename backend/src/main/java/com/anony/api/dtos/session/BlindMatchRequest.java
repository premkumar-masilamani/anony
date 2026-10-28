package com.anony.api.dtos.session;

import com.anony.domain.session.BookingType;
import com.anony.domain.session.TimeWindow;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Unified data transfer object for RESTful session booking requests (both free blind matches
 * and direct paid coach/slot bookings) via {@code POST /api/v1/sessions}.
 *
 * @param bookingType optional explicit booking mode ({@code FREE} or {@code PAID})
 * @param isProBono optional boolean flag indicating a pro-bono session ({@code true} for free, {@code false} for paid)
 * @param coachId target coach identifier (required for paid bookings)
 * @param slotId target slot identifier (required for paid bookings)
 * @param domainCode optional coaching domain code filter or tag (e.g. {@code BURNOUT}, {@code CAREER})
 * @param strugglePrompt description of current personal, life, or leadership struggle / session topic
 * @param preferredTimeWindow optional preferred time of day for free blind match
 * @param preferredDate optional requested date for free blind match
 */
public record BlindMatchRequest(
    @JsonProperty("booking_type")
    BookingType bookingType,

    @JsonProperty("is_pro_bono")
    Boolean isProBono,

    @JsonProperty("coach_id")
    UUID coachId,

    @JsonProperty("slot_id")
    UUID slotId,

    @JsonProperty("domain_code")
    String domainCode,

    @JsonProperty("struggle_prompt")
    String strugglePrompt,

    @JsonProperty("preferred_time_window")
    TimeWindow preferredTimeWindow,

    @JsonProperty("preferred_date")
    LocalDate preferredDate) {}
