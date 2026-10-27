package com.anony.api.dtos.auth;

/**
 * Response payload returned upon successful session termination.
 *
 * @param message confirmation message
 */
public record LogoutResponse(String message) {}
