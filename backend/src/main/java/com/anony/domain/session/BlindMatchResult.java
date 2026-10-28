package com.anony.domain.session;

import java.time.Instant;
import java.util.UUID;

/**
 * Unified domain result representing an atomically locked and scheduled coaching session
 * (either free pro-bono blind match or paid direct booking).
 *
 * @param sessionId unique session identifier
 * @param slotId locked slot identifier
 * @param coachId coach identifier
 * @param coachAlias procedural or display alias of the coach
 * @param coachIcfLevel coach verified ICF credential level
 * @param domainCode resolved coaching domain code
 * @param topic session topic or struggle summary
 * @param scheduledTime scheduled start time in UTC
 * @param endTime scheduled end time in UTC
 * @param bookingType booking mode ({@code FREE} or {@code PAID})
 * @param status booking status ({@code CONFIRMED})
 * @param awaitingCheckout whether the session is awaiting payment checkout
 * @param isProBono whether session is free pro-bono pledge
 * @param freeSessionsUsed number of pro-bono sessions utilized by the client
 * @param maxFreeSessions platform lifetime allowance cap
 * @param nextFreeSessionAvailableAt timestamp when the client becomes eligible for next pro-bono session
 */
public record BlindMatchResult(
    UUID sessionId,
    UUID slotId,
    UUID coachId,
    String coachAlias,
    String coachIcfLevel,
    String domainCode,
    String topic,
    Instant scheduledTime,
    Instant endTime,
    BookingType bookingType,
    String status,
    boolean awaitingCheckout,
    boolean isProBono,
    int freeSessionsUsed,
    int maxFreeSessions,
    Instant nextFreeSessionAvailableAt) {}
