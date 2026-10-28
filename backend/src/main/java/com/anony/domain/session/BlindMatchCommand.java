package com.anony.domain.session;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Domain command for initiating an automated pro-bono blind match.
 *
 * @param userId client user identifier
 * @param strugglePrompt client's description of their current struggle or goals
 * @param preferredTimeWindow desired time of day for the session
 * @param preferredDate requested date for the pro-bono session
 */
public record BlindMatchCommand(
    UUID userId,
    String strugglePrompt,
    TimeWindow preferredTimeWindow,
    LocalDate preferredDate) {}
