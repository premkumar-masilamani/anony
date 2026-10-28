package com.anony.api.dtos.client;

import java.time.Instant;
import java.util.UUID;

/**
 * Data transfer object representing a client's profile.
 *
 * @param clientId unique client identifier
 * @param userId associated user identifier
 * @param email client email address
 * @param firstName client first name
 * @param lastName client last name
 * @param alias procedural anonymous alias
 * @param isAnonymous whether client is anonymous
 * @param isOnboarded whether client has completed onboarding
 * @param isAnonymousMode whether client has enabled blind matching anonymous mode
 * @param freeSessionsCount number of pro-bono sessions used
 * @param lastFreeSessionAt timestamp of the last pro-bono session booked
 * @param createdAt timestamp when client profile was created
 */
public record ClientProfileDto(
    UUID clientId,
    UUID userId,
    String email,
    String firstName,
    String lastName,
    String alias,
    Boolean isAnonymous,
    Boolean isOnboarded,
    Boolean isAnonymousMode,
    Integer freeSessionsCount,
    Instant lastFreeSessionAt,
    Instant createdAt) {}
