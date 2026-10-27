package com.anony.domain.auth;

import com.anony.persistence.enums.UserRole;
import java.util.UUID;

/**
 * Domain outcome of a successful user authentication.
 *
 * @param userId unique user identifier
 * @param email user email address
 * @param role assigned domain role
 * @param token issued signed Bearer JWT
 * @param expiresIn token expiration window in seconds
 */
public record AuthenticationResult(
    UUID userId,
    String email,
    UserRole role,
    String token,
    long expiresIn) {}
