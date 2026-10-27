package com.anony.api.dtos.auth;

import com.anony.persistence.enums.UserRole;
import java.util.UUID;

/**
 * Summary view of an authenticated user.
 *
 * @param userId unique user identifier
 * @param email user email address
 * @param role assigned domain role
 */
public record UserSummaryDto(
    UUID userId,
    String email,
    UserRole role) {}
