package com.anony.domain.security;

import com.anony.persistence.enums.UserRole;
import java.io.Serializable;
import java.util.UUID;

/**
 * Immutable authenticated principal stored in the Spring Security context.
 *
 * @param userId unique user identifier
 * @param email user email address
 * @param role assigned domain role
 * @param tokenId identifier of the active session token
 */
public record AuthenticatedUser(
    UUID userId,
    String email,
    UserRole role,
    UUID tokenId) implements Serializable {}
