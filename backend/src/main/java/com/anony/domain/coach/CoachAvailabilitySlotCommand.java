package com.anony.domain.coach;

import java.time.Instant;

/**
 * Domain command representing a single availability slot to be published by a coach.
 *
 * @param startAt slot start timestamp in UTC
 * @param endAt slot end timestamp in UTC
 * @param durationMinutes slot duration in minutes (30 or 60)
 * @param isFreePledge whether the slot counts toward the mandatory 1-hour monthly free pledge
 */
public record CoachAvailabilitySlotCommand(
    Instant startAt,
    Instant endAt,
    Integer durationMinutes,
    Boolean isFreePledge) {}
