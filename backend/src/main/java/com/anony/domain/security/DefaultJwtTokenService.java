package com.anony.domain.security;

import com.anony.persistence.enums.UserRole;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Default implementation of {@link JwtTokenService} using standard JJWT.
 */
@Service
public class DefaultJwtTokenService implements JwtTokenService {

  private static final Logger LOGGER = LoggerFactory.getLogger(DefaultJwtTokenService.class);

  private final TokenProperties tokenProperties;
  private final SecretKey signingKey;

  /**
   * Constructs the JWT service with configured token properties.
   *
   * @param tokenProperties application token properties
   */
  public DefaultJwtTokenService(TokenProperties tokenProperties) {
    this.tokenProperties = tokenProperties;
    this.signingKey =
        Keys.hmacShaKeyFor(tokenProperties.getSecret().getBytes(StandardCharsets.UTF_8));
  }

  @Override
  public String generateToken(
      UUID userId, String email, UserRole role, UUID tokenId) {
    if (userId != null && StringUtils.isNotBlank(email) && role != null && tokenId != null) {
      Instant currentTimestamp = Instant.now();
      Instant expirationTimestamp =
          currentTimestamp.plusSeconds(tokenProperties.getExpirationSeconds());

      LOGGER.debug(
          "Generating signed JWT for userId={}, role={}, tokenId={}, expiresAt={}",
          userId,
          role,
          tokenId,
          expirationTimestamp);

      return Jwts.builder()
          .subject(userId.toString())
          .id(tokenId.toString())
          .claim("email", email)
          .claim("role", role.name())
          .issuedAt(Date.from(currentTimestamp))
          .expiration(Date.from(expirationTimestamp))
          .signWith(signingKey)
          .compact();
    } else {
      LOGGER.warn("Rejected JWT generation due to missing required claims.");
      throw new IllegalArgumentException(
          "User identifier, email, role, and token identifier must all be non-null and non-blank.");
    }
  }

  @Override
  public AuthenticatedUser parseAndValidateToken(String token) {
    if (StringUtils.isNotBlank(token)) {
      Claims claims =
          Jwts.parser()
              .verifyWith(signingKey)
              .build()
              .parseSignedClaims(token)
              .getPayload();

      UUID parsedUserId = UUID.fromString(claims.getSubject());
      UUID parsedTokenId = UUID.fromString(claims.getId());
      String extractedEmail = claims.get("email", String.class);
      String roleString = claims.get("role", String.class);
      UserRole parsedRole = UserRole.valueOf(roleString);

      LOGGER.debug(
          "Validated JWT claims for userId={}, role={}, tokenId={}",
          parsedUserId,
          parsedRole,
          parsedTokenId);

      return new AuthenticatedUser(parsedUserId, extractedEmail, parsedRole, parsedTokenId);
    } else {
      LOGGER.warn("Rejected JWT validation: token string was blank or null.");
      throw new IllegalArgumentException("Token cannot be blank or null.");
    }
  }
}
