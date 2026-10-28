package com.anony.domain.security;

import jakarta.annotation.PostConstruct;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Encapsulates JWT cryptographic and lifecycle properties with fail-fast validation.
 */
@Component
public class TokenProperties {

  /**
   * Standard JWT lifetime in seconds (30 days).
   */
  public static final long JWT_EXPIRATION_SECONDS = 2592000L;

  private static final Logger LOGGER = LoggerFactory.getLogger(TokenProperties.class);

  private final String secret;
  private final long expirationSeconds;

  /**
   * Constructs token properties from application configuration using the constant expiration time.
   *
   * @param secret secret key used to sign and verify HMAC-SHA256 JWTs
   */
  @Autowired
  public TokenProperties(@Value("${anony.security.jwt.secret}") String secret) {
    this(secret, JWT_EXPIRATION_SECONDS);
  }

  /**
   * Constructs token properties with an explicit expiration duration.
   *
   * @param secret secret key used to sign and verify HMAC-SHA256 JWTs
   * @param expirationSeconds lifetime of issued tokens in seconds
   */
  public TokenProperties(String secret, long expirationSeconds) {
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
      LOGGER.info(
          "JWT configuration properties verified (expirationSeconds={}).",
          expirationSeconds);
    } else {
      LOGGER.warn("Invalid JWT configuration properties detected during startup validation.");
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
