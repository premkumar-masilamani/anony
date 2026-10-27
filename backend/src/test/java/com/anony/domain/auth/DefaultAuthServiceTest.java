package com.anony.domain.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.anony.domain.security.JwtTokenService;
import com.anony.domain.security.PasswordService;
import com.anony.domain.security.TokenProperties;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.UserRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;

@ExtendWith(MockitoExtension.class)
class DefaultAuthServiceTest {

  @Mock
  private UserRepository userRepository;

  @Mock
  private PasswordService passwordService;

  @Mock
  private JwtTokenService jwtTokenService;

  private TokenProperties tokenProperties;
  private DefaultAuthService authService;

  @BeforeEach
  void setUp() {
    tokenProperties =
        new TokenProperties(
            "supersecretjwtkeythatisatleast256bitslongforhmacsha256signing!", 2592000L);
    authService =
        new DefaultAuthService(
            userRepository, passwordService, jwtTokenService, tokenProperties);
  }

  @Test
  @DisplayName("Should successfully authenticate user, update token in DB, and issue JWT")
  void testAuthenticateSuccess() {
    String email = "maya.raman@example.com";
    final String rawPassword = "AnonyDemo#2026";
    String hashedPassword = "$2a$10$hashedPassword";

    UUID userId = UUID.randomUUID();
    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setEmail(email);
    userEntity.setPasswordHash(hashedPassword);
    userEntity.setRole(UserRole.COACH);

    when(userRepository.findByEmailIgnoreCase(email)).thenReturn(Optional.of(userEntity));
    when(passwordService.verifyPassword(rawPassword, hashedPassword)).thenReturn(true);
    when(jwtTokenService.generateToken(eq(userId), eq(email), eq(UserRole.COACH), any(UUID.class)))
        .thenReturn("mock.jwt.token");
    when(userRepository.save(any(UserEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    AuthenticationResult result = authService.authenticate(email, rawPassword);

    assertNotNull(result);
    assertEquals(userId, result.userId());
    assertEquals(email, result.email());
    assertEquals(UserRole.COACH, result.role());
    assertEquals("mock.jwt.token", result.token());
    assertEquals(2592000L, result.expiresIn());

    assertNotNull(userEntity.getTokenId());
    assertNotNull(userEntity.getTokenExpiresAt());
    verify(userRepository).save(userEntity);
  }

  @Test
  @DisplayName("Should throw BadCredentialsException when user email does not exist")
  void testAuthenticateUserNotFound() {
    String email = "unknown@example.com";
    when(userRepository.findByEmailIgnoreCase(email)).thenReturn(Optional.empty());

    assertThrows(
        BadCredentialsException.class,
        () -> authService.authenticate(email, "password"));
  }

  @Test
  @DisplayName("Should throw BadCredentialsException when password does not match")
  void testAuthenticatePasswordMismatch() {
    String email = "maya.raman@example.com";
    final String rawPassword = "wrongPassword";
    String hashedPassword = "$2a$10$hashedPassword";

    UserEntity userEntity = new UserEntity();
    userEntity.setEmail(email);
    userEntity.setPasswordHash(hashedPassword);

    when(userRepository.findByEmailIgnoreCase(email)).thenReturn(Optional.of(userEntity));
    when(passwordService.verifyPassword(rawPassword, hashedPassword)).thenReturn(false);

    assertThrows(
        BadCredentialsException.class,
        () -> authService.authenticate(email, rawPassword));
  }

  @Test
  @DisplayName("Should throw IllegalArgumentException when email or password is blank")
  void testAuthenticateBlankInputs() {
    assertThrows(
        IllegalArgumentException.class,
        () -> authService.authenticate("  ", "password"));
    assertThrows(
        IllegalArgumentException.class,
        () -> authService.authenticate("user@example.com", "   "));
  }

  @Test
  @DisplayName("Should successfully clear active token in database on logout")
  void testLogoutSuccess() {
    UUID userId = UUID.randomUUID();
    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setTokenId(UUID.randomUUID());

    when(userRepository.findById(userId)).thenReturn(Optional.of(userEntity));
    when(userRepository.save(any(UserEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    authService.logout(userId);

    assertNull(userEntity.getTokenId());
    assertNull(userEntity.getTokenExpiresAt());
    verify(userRepository).save(userEntity);
  }

  @Test
  @DisplayName("Should throw IllegalArgumentException when logout userId is null")
  void testLogoutNullUserId() {
    assertThrows(IllegalArgumentException.class, () -> authService.logout(null));
  }

  @Test
  @DisplayName("Should throw IllegalStateException when logout userId is not found in database")
  void testLogoutUserNotFound() {
    UUID userId = UUID.randomUUID();
    when(userRepository.findById(userId)).thenReturn(Optional.empty());

    assertThrows(IllegalStateException.class, () -> authService.logout(userId));
  }

  @Test
  @DisplayName("Should verify AuthenticationResult record methods")
  void testAuthenticationResultRecord() {
    UUID userId = UUID.randomUUID();
    AuthenticationResult resultOne =
        new AuthenticationResult(userId, "test@example.com", UserRole.CLIENT, "token1", 100L);
    AuthenticationResult resultTwo =
        new AuthenticationResult(userId, "test@example.com", UserRole.CLIENT, "token1", 100L);

    assertEquals(resultOne, resultTwo);
    assertEquals(resultOne.hashCode(), resultTwo.hashCode());
    assertNotNull(resultOne.toString());
  }
}
