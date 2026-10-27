package com.anony.domain.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.anony.persistence.enums.UserRole;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class AuthenticatedUserTest {

  @Test
  @DisplayName("Should correctly hold properties and support equality and string representation")
  void testAuthenticatedUserRecord() {
    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();
    String email = "test@example.com";
    UserRole role = UserRole.COACH;

    AuthenticatedUser userOne = new AuthenticatedUser(userId, email, role, tokenId);
    final AuthenticatedUser userTwo = new AuthenticatedUser(userId, email, role, tokenId);
    final AuthenticatedUser userThree = new AuthenticatedUser(UUID.randomUUID(), email, role, tokenId);

    assertEquals(userId, userOne.userId());
    assertEquals(email, userOne.email());
    assertEquals(role, userOne.role());
    assertEquals(tokenId, userOne.tokenId());

    assertEquals(userOne, userTwo);
    assertEquals(userOne.hashCode(), userTwo.hashCode());
    assertNotEquals(userOne, userThree);
    assertNotNull(userOne.toString());
  }
}
