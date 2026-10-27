package com.anony.domain.security;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class DefaultPasswordServiceTest {

  private DefaultPasswordService passwordService;

  @BeforeEach
  void setUp() {
    passwordService = new DefaultPasswordService();
  }

  @Test
  @DisplayName("Should successfully hash password and verify matches")
  void testHashAndVerifyPasswordSuccess() {
    String rawPassword = "AnonyDemo#2026";
    String hashedPassword = passwordService.hashPassword(rawPassword);

    assertNotNull(hashedPassword);
    assertTrue(passwordService.verifyPassword(rawPassword, hashedPassword));
    assertFalse(passwordService.verifyPassword("WrongPassword123", hashedPassword));
  }

  @Test
  @DisplayName("Should throw IllegalArgumentException when hashing blank password")
  void testHashPasswordThrowsOnBlank() {
    assertThrows(IllegalArgumentException.class, () -> passwordService.hashPassword("   "));
    assertThrows(IllegalArgumentException.class, () -> passwordService.hashPassword(null));
  }

  @Test
  @DisplayName("Should return false when verifying with blank raw or hashed password")
  void testVerifyPasswordReturnsFalseOnBlank() {
    assertFalse(passwordService.verifyPassword(null, "someHash"));
    assertFalse(passwordService.verifyPassword("password", null));
    assertFalse(passwordService.verifyPassword("   ", "someHash"));
  }

  @Test
  @DisplayName("Should successfully construct DefaultPasswordService with custom encoder")
  void testCustomPasswordEncoderConstructor() {
    org.springframework.security.crypto.password.PasswordEncoder customEncoder =
        org.mockito.Mockito.mock(org.springframework.security.crypto.password.PasswordEncoder.class);
    DefaultPasswordService customService = new DefaultPasswordService(customEncoder);
    assertNotNull(customService);
  }
}
