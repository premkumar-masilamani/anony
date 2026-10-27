package com.anony.domain.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class TokenPropertiesTest {

  @Test
  @DisplayName("Should validate successfully when secret and positive expiration seconds are provided")
  void testValidateConfigurationSuccess() {
    String validSecret = "supersecretjwtkeythatisatleast256bitslongforhmacsha256signing!";
    long validExpirationSeconds = 2592000L;
    TokenProperties tokenProperties = new TokenProperties(validSecret, validExpirationSeconds);

    tokenProperties.validateConfiguration();

    assertEquals(validSecret, tokenProperties.getSecret());
    assertEquals(validExpirationSeconds, tokenProperties.getExpirationSeconds());
  }

  @Test
  @DisplayName("Should throw IllegalStateException when secret is blank")
  void testValidateConfigurationFailsWhenSecretIsBlank() {
    TokenProperties tokenProperties = new TokenProperties("   ", 2592000L);

    assertThrows(IllegalStateException.class, tokenProperties::validateConfiguration);
  }

  @Test
  @DisplayName("Should throw IllegalStateException when secret is unexpanded placeholder")
  void testValidateConfigurationFailsWhenSecretIsUnexpanded() {
    TokenProperties tokenProperties = new TokenProperties("${JWT_SECRET}", 2592000L);

    assertThrows(IllegalStateException.class, tokenProperties::validateConfiguration);
  }

  @Test
  @DisplayName("Should throw IllegalStateException when expiration seconds is zero or negative")
  void testValidateConfigurationFailsWhenExpirationSecondsIsZeroOrNegative() {
    String validSecret = "supersecretjwtkeythatisatleast256bitslongforhmacsha256signing!";
    TokenProperties tokenPropertiesWithZero = new TokenProperties(validSecret, 0L);
    TokenProperties tokenPropertiesWithNegative = new TokenProperties(validSecret, -100L);

    assertThrows(IllegalStateException.class, tokenPropertiesWithZero::validateConfiguration);
    assertThrows(IllegalStateException.class, tokenPropertiesWithNegative::validateConfiguration);
  }
}
