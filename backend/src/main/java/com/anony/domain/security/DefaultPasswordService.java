package com.anony.domain.security;

import org.apache.commons.lang3.StringUtils;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Default implementation of {@link PasswordService} using {@link BCryptPasswordEncoder}.
 */
@Service
public class DefaultPasswordService implements PasswordService {

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
      return passwordEncoder.encode(rawPassword);
    } else {
      throw new IllegalArgumentException("Raw password cannot be blank.");
    }
  }

  @Override
  public boolean verifyPassword(String rawPassword, String hashedPassword) {
    if (StringUtils.isNotBlank(rawPassword) && StringUtils.isNotBlank(hashedPassword)) {
      return passwordEncoder.matches(rawPassword, hashedPassword);
    } else {
      return false;
    }
  }
}
