package com.anony.api.dtos.coach;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

/**
 * Data transfer object representing a single availability slot in a publish request.
 *
 * @param startAt slot start timestamp in UTC
 * @param endAt slot end timestamp in UTC
 * @param durationMinutes slot duration in minutes (30 or 60)
 * @param isFreePledge whether the slot is offered as a free anonymous session pledge
 */
public record CoachAvailabilitySlotRequest(
    @NotNull(message = "Slot start timestamp is required")
        @JsonAlias({"start_at", "startTime"})
        Instant startAt,
    @NotNull(message = "Slot end timestamp is required")
        @JsonAlias({"end_at", "endTime"})
        Instant endAt,
    @NotNull(message = "Slot duration is required")
        @JsonAlias({"duration_minutes", "duration"})
        Integer durationMinutes,
    @NotNull(message = "Free pledge indicator is required")
        @JsonAlias({"is_free_pledge", "freePledge"})
        Boolean isFreePledge) {}
