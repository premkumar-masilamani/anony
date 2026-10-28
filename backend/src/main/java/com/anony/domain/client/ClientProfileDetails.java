package com.anony.domain.client;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain record containing full client profile details.
 *
 * @param clientId unique client identifier
 * @param userId associated user identifier
 * @param email client email address
 * @param firstName client first name
 * @param lastName client last name
 * @param alias client procedural anonymous alias
 * @param isAnonymous whether client participates anonymously
 * @param isOnboarded whether client has completed onboarding
 * @param isAnonymousMode whether client has enabled blind matching anonymous mode
 * @param freeSessionsCount number of pro-bono sessions utilized
 * @param lastFreeSessionAt timestamp of the last pro-bono session booked
 * @param createdAt timestamp when client profile was created
 */
public record ClientProfileDetails(
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
