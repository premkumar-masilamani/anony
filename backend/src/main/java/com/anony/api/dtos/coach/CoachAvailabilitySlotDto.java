package com.anony.api.dtos.coach;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.UUID;

/**
 * Data transfer object representing a published coach availability slot.
 *
 * @param slotId unique slot identifier
 * @param coachId unique coach identifier
 * @param startAt slot start timestamp in UTC
 * @param endAt slot end timestamp in UTC
 * @param durationMinutes slot duration in minutes (30 or 60)
 * @param isFreePledge whether the slot is offered as a free anonymous session pledge
 * @param isBooked whether the slot is booked
 */
public record CoachAvailabilitySlotDto(
    UUID slotId,
    UUID coachId,
    Instant startAt,
    Instant endAt,
    int durationMinutes,
    boolean isFreePledge,
    boolean isBooked) {

  /**
   * Exposes snake_case alias for API consumers expecting {@code is_free_pledge}.
   *
   * @return true if this slot is designated as a free pledge session
   */
  @JsonProperty("is_free_pledge")
  public boolean isFreePledgeSnakeCase() {
    return isFreePledge;
  }
}
