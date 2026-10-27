package com.anony.domain.session;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain result representing an atomically confirmed pro-bono coaching session match.
 *
 * @param sessionId unique session identifier
 * @param coachAlias procedural alias of matched coach
 * @param coachIcfLevel coach verified ICF credential level
 * @param topic session topic or struggle summary
 * @param scheduledTime scheduled start time in UTC
 * @param status booking status (CONFIRMED)
 * @param isProBono whether session is free pro-bono pledge
 * @param freeSessionsUsed number of pro-bono sessions utilized including this session
 * @param maxFreeSessions platform lifetime allowance cap
 * @param nextFreeSessionAvailableAt timestamp when the client becomes eligible for next pro-bono session
 */
public record BlindMatchResult(
    UUID sessionId,
    String coachAlias,
    String coachIcfLevel,
    String topic,
    Instant scheduledTime,
    String status,
    boolean isProBono,
    int freeSessionsUsed,
    int maxFreeSessions,
    Instant nextFreeSessionAvailableAt) {}
