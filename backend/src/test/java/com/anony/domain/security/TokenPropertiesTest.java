package com.anony.domain.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class TokenPropertiesTest {

  @Test
  @DisplayName("Should validate successfully when secret is provided and use constant JWT_EXPIRATION_SECONDS")
  void testValidateConfigurationSuccess() {
    String validSecret = "supersecretjwtkeythatisatleast256bitslongforhmacsha256signing!";
    TokenProperties tokenProperties = new TokenProperties(validSecret);

    tokenProperties.validateConfiguration();

    assertEquals(validSecret, tokenProperties.getSecret());
    assertEquals(TokenProperties.JWT_EXPIRATION_SECONDS, tokenProperties.getExpirationSeconds());
  }

  @Test
  @DisplayName("Should throw IllegalStateException when secret is blank")
  void testValidateConfigurationFailsWhenSecretIsBlank() {
    TokenProperties tokenProperties = new TokenProperties("   ");

    assertThrows(IllegalStateException.class, tokenProperties::validateConfiguration);
  }

  @Test
  @DisplayName("Should throw IllegalStateException when secret is unexpanded placeholder")
  void testValidateConfigurationFailsWhenSecretIsUnexpanded() {
    TokenProperties tokenProperties = new TokenProperties("${ANONY_JWT_SECRET}");

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
