package com.anony.domain.coach;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain model representing a persisted coach availability slot.
 *
 * @param slotId unique slot identifier
 * @param coachId unique coach identifier
 * @param startAt slot start timestamp in UTC
 * @param endAt slot end timestamp in UTC
 * @param durationMinutes slot duration in minutes (30 or 60)
 * @param isFreePledge whether the slot is designated as a free anonymous session pledge
 * @param isBooked whether the slot is currently booked by a client
 */
public record CoachAvailabilitySlotDetails(
    UUID slotId,
    UUID coachId,
    Instant startAt,
    Instant endAt,
    int durationMinutes,
    boolean isFreePledge,
    boolean isBooked) {}
