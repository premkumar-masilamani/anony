package com.anony.api.dtos.coach;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

/**
 * Data transfer object representing a batch request to publish coach availability slots.
 *
 * @param slots non-empty list of availability slots to publish
 */
public record CoachAvailabilityPublishRequest(
    @NotEmpty(message = "At least one availability slot must be provided")
        @Valid
        List<CoachAvailabilitySlotRequest> slots) {}
