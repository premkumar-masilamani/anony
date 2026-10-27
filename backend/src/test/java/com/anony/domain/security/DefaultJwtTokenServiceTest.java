package com.anony.domain.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.anony.persistence.enums.UserRole;
import io.jsonwebtoken.JwtException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class DefaultJwtTokenServiceTest {

  private static final String SECRET =
      "supersecretjwtkeythatisatleast256bitslongforhmacsha256signing!";
  private TokenProperties tokenProperties;
  private DefaultJwtTokenService jwtTokenService;

  @BeforeEach
  void setUp() {
    tokenProperties = new TokenProperties(SECRET, 3600L);
    jwtTokenService = new DefaultJwtTokenService(tokenProperties);
  }

  @Test
  @DisplayName("Should generate a valid JWT and successfully parse its claims")
  void testGenerateAndParseTokenSuccess() {
    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();
    String email = "maya.raman@example.com";
    UserRole role = UserRole.COACH;

    String token = jwtTokenService.generateToken(userId, email, role, tokenId);

    assertNotNull(token);
    AuthenticatedUser principal = jwtTokenService.parseAndValidateToken(token);

    assertEquals(userId, principal.userId());
    assertEquals(email, principal.email());
    assertEquals(role, principal.role());
    assertEquals(tokenId, principal.tokenId());
  }

  @Test
  @DisplayName("Should throw JwtException when token is expired")
  void testParseExpiredTokenThrowsException() {
    TokenProperties expiredProperties = new TokenProperties(SECRET, -10L);
    DefaultJwtTokenService expiredTokenService = new DefaultJwtTokenService(expiredProperties);

    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();
    String token =
        expiredTokenService.generateToken(userId, "expired@example.com", UserRole.CLIENT, tokenId);

    assertThrows(JwtException.class, () -> jwtTokenService.parseAndValidateToken(token));
  }

  @Test
  @DisplayName("Should throw JwtException when token is signed with a different key")
  void testParseTokenWithDifferentKeyThrowsException() {
    TokenProperties differentProperties =
        new TokenProperties(
            "anotherdifferentsecretkeythatisatleast256bitslongforhmacsha256!", 3600L);
    DefaultJwtTokenService differentTokenService =
        new DefaultJwtTokenService(differentProperties);

    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();
    String token =
        differentTokenService.generateToken(
            userId, "different@example.com", UserRole.CLIENT, tokenId);

    assertThrows(JwtException.class, () -> jwtTokenService.parseAndValidateToken(token));
  }

  @Test
  @DisplayName("Should throw JwtException when token is malformed")
  void testParseMalformedTokenThrowsException() {
    assertThrows(
        JwtException.class, () -> jwtTokenService.parseAndValidateToken("malformed.jwt.token"));
  }

  @Test
  @DisplayName("Should throw IllegalArgumentException when parsing blank or null token")
  void testParseBlankTokenThrowsException() {
    assertThrows(
        IllegalArgumentException.class, () -> jwtTokenService.parseAndValidateToken("   "));
    assertThrows(IllegalArgumentException.class, () -> jwtTokenService.parseAndValidateToken(null));
  }

  @Test
  @DisplayName("Should throw IllegalArgumentException when generating token with null arguments")
  void testGenerateTokenWithNullArgumentsThrowsException() {
    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();

    assertThrows(
        IllegalArgumentException.class,
        () -> jwtTokenService.generateToken(null, "email@example.com", UserRole.COACH, tokenId));
    assertThrows(
        IllegalArgumentException.class,
        () -> jwtTokenService.generateToken(userId, null, UserRole.COACH, tokenId));
    assertThrows(
        IllegalArgumentException.class,
        () -> jwtTokenService.generateToken(userId, "email@example.com", null, tokenId));
    assertThrows(
        IllegalArgumentException.class,
        () -> jwtTokenService.generateToken(userId, "email@example.com", UserRole.COACH, null));
  }
}
