package com.anony.domain.security;

import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Default implementation of {@link PasswordService} using {@link BCryptPasswordEncoder}.
 */
@Service
public class DefaultPasswordService implements PasswordService {

  private static final Logger LOGGER = LoggerFactory.getLogger(DefaultPasswordService.class);

  private final PasswordEncoder passwordEncoder;

  public DefaultPasswordService() {
    this.passwordEncoder = new BCryptPasswordEncoder();
  }

  public DefaultPasswordService(PasswordEncoder passwordEncoder) {
    this.passwordEncoder = passwordEncoder;
  }

  @Override
  public String hashPassword(String rawPassword) {
    if (StringUtils.isNotBlank(rawPassword)) {
      LOGGER.debug("Hashing password using configured PasswordEncoder.");
      return passwordEncoder.encode(rawPassword);
    } else {
      LOGGER.warn("Password hashing rejected: raw password was blank.");
      throw new IllegalArgumentException("Raw password cannot be blank.");
    }
  }

  @Override
  public boolean verifyPassword(String rawPassword, String hashedPassword) {
    if (StringUtils.isNotBlank(rawPassword) && StringUtils.isNotBlank(hashedPassword)) {
      boolean matches = passwordEncoder.matches(rawPassword, hashedPassword);
      LOGGER.debug("Verified password against stored hash (matches={}).", matches);
      return matches;
    } else {
      LOGGER.warn("Password verification failed: raw password or stored hash was blank.");
      return false;
    }
  }
}
