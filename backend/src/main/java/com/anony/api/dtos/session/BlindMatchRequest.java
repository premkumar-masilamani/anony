package com.anony.api.dtos.session;

import com.anony.domain.session.TimeWindow;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDate;

/**
 * Data transfer object for pro-bono blind match requests.
 *
 * @param strugglePrompt description of current personal, life, or leadership struggle
 * @param preferredTimeWindow optional preferred time of day (MORNING, AFTERNOON, EVENING, ANYTIME)
 * @param preferredDate optional requested date for the pro-bono session
 */
public record BlindMatchRequest(
    @NotBlank(message = "struggle_prompt cannot be blank")
    @JsonProperty("struggle_prompt")
    String strugglePrompt,

    @JsonProperty("preferred_time_window")
    TimeWindow preferredTimeWindow,

    @JsonProperty("preferred_date")
    LocalDate preferredDate) {}
