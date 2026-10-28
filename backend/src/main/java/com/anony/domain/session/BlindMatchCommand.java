package com.anony.domain.session;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Unified domain command for booking a coaching session (either free blind match or paid direct slot booking).
 *
 * @param userId authenticated client user identifier
 * @param bookingType resolved booking mode ({@code FREE} or {@code PAID})
 * @param coachId target coach identifier for paid bookings
 * @param slotId target slot identifier for paid bookings
 * @param domainCode optional coaching domain code filter or tag
 * @param strugglePrompt client's description of their current struggle or session topic
 * @param preferredTimeWindow desired time of day for free blind match
 * @param preferredDate requested date for free blind match
 */
public record BlindMatchCommand(
    UUID userId,
    BookingType bookingType,
    UUID coachId,
    UUID slotId,
    String domainCode,
    String strugglePrompt,
    TimeWindow preferredTimeWindow,
    LocalDate preferredDate) {}
