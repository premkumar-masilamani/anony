package com.anony.domain.security;

import jakarta.annotation.PostConstruct;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Encapsulates JWT cryptographic and lifecycle properties with fail-fast validation.
 */
@Component
public class TokenProperties {

  private final String secret;
  private final long expirationSeconds;

  /**
   * Constructs token properties from application configuration.
   *
   * @param secret secret key used to sign and verify HMAC-SHA256 JWTs
   * @param expirationSeconds lifetime of issued tokens in seconds
   */
  public TokenProperties(
      @Value("${anony.security.jwt.secret}") String secret,
      @Value("${anony.security.jwt.expiration-seconds}") long expirationSeconds) {
    this.secret = secret;
    this.expirationSeconds = expirationSeconds;
  }

  /**
   * Validates that required configuration is present, expanded, and structurally valid.
   */
  @PostConstruct
  public void validateConfiguration() {
    boolean isValidConfiguration =
        StringUtils.isNotBlank(secret)
            && !secret.startsWith("${")
            && expirationSeconds > 0;

    if (isValidConfiguration) {
      // Configuration parameters are fully defined and valid
      org.slf4j.LoggerFactory.getLogger(TokenProperties.class)
          .debug("JWT configuration properties successfully verified.");
    } else {
      throw new IllegalStateException(
          "JWT configuration properties must be present, expanded, and positive.");
    }
  }

  public String getSecret() {
    return secret;
  }

  public long getExpirationSeconds() {
    return expirationSeconds;
  }
}
