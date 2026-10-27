package com.anony.api.dtos.auth;

/**
 * Response payload returned upon successful login.
 *
 * @param token issued signed Bearer JWT
 * @param expiresIn token validity duration in seconds
 * @param user summary of the authenticated user
 */
public record LoginResponse(
    String token,
    long expiresIn,
    UserSummaryDto user) {}
