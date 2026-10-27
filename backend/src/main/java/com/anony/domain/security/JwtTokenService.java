package com.anony.domain.security;

import com.anony.persistence.enums.UserRole;
import java.util.UUID;

/**
 * Service contract for generating, parsing, and validating HMAC-SHA256 JWT Bearer tokens.
 */
public interface JwtTokenService {

  /**
   * Generates a signed JWT for the authenticated user.
   *
   * @param userId unique user identifier
   * @param email user email address
   * @param role assigned domain role
   * @param tokenId unique active session identifier (jti)
   * @return signed JWT compact string
   */
  String generateToken(UUID userId, String email, UserRole role, UUID tokenId);

  /**
   * Parses and cryptographically validates the provided Bearer token.
   *
   * @param token compact JWT Bearer token string
   * @return authenticated user principal extracted from the token
   */
  AuthenticatedUser parseAndValidateToken(String token);
}
