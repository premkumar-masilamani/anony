package com.anony.domain.auth;

import com.anony.domain.security.JwtTokenService;
import com.anony.domain.security.PasswordService;
import com.anony.domain.security.TokenProperties;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.repositories.UserRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Default implementation of {@link AuthService}.
 */
@Service
public class DefaultAuthService implements AuthService {

  private static final Logger LOGGER = LoggerFactory.getLogger(DefaultAuthService.class);

  private final UserRepository userRepository;
  private final PasswordService passwordService;
  private final JwtTokenService jwtTokenService;
  private final TokenProperties tokenProperties;

  /**
   * Constructs the authentication service with required dependencies.
   *
   * @param userRepository repository for accessing user records
   * @param passwordService service for verifying passwords
   * @param jwtTokenService service for signing JWTs
   * @param tokenProperties configuration properties for tokens
   */
  public DefaultAuthService(
      UserRepository userRepository,
      PasswordService passwordService,
      JwtTokenService jwtTokenService,
      TokenProperties tokenProperties) {
    this.userRepository = userRepository;
    this.passwordService = passwordService;
    this.jwtTokenService = jwtTokenService;
    this.tokenProperties = tokenProperties;
  }

  @Override
  @Transactional
  public AuthenticationResult authenticate(String email, String rawPassword) {
    if (StringUtils.isNotBlank(email) && StringUtils.isNotBlank(rawPassword)) {
      LOGGER.debug("Authenticating user with email={}", email);
      Optional<UserEntity> userOptional = userRepository.findByEmailIgnoreCase(email);

      if (userOptional.isPresent()) {
        UserEntity userEntity = userOptional.get();

        if (passwordService.verifyPassword(rawPassword, userEntity.getPasswordHash())) {
          UUID activeTokenIdentifier = UUID.randomUUID();
          Instant expirationTimestamp =
              Instant.now().plusSeconds(tokenProperties.getExpirationSeconds());

          userEntity.setTokenId(activeTokenIdentifier);
          userEntity.setTokenExpiresAt(expirationTimestamp);
          userRepository.save(userEntity);

          String issuedBearerToken =
              jwtTokenService.generateToken(
                  userEntity.getUserId(),
                  userEntity.getEmail(),
                  userEntity.getRole(),
                  activeTokenIdentifier);

          LOGGER.info(
              "Authenticated userId={} (email={}, role={}) with active tokenId={}",
              userEntity.getUserId(),
              userEntity.getEmail(),
              userEntity.getRole(),
              activeTokenIdentifier);

          return new AuthenticationResult(
              userEntity.getUserId(),
              userEntity.getEmail(),
              userEntity.getRole(),
              issuedBearerToken,
              tokenProperties.getExpirationSeconds());
        } else {
          LOGGER.warn("Authentication failed: password mismatch for email={}", email);
          throw new BadCredentialsException("Invalid email or password.");
        }
      } else {
        LOGGER.warn("Authentication failed: no user account found for email={}", email);
        throw new BadCredentialsException("Invalid email or password.");
      }
    } else {
      LOGGER.warn("Authentication rejected: email or password was blank.");
      throw new IllegalArgumentException("Email and password cannot be blank.");
    }
  }

  @Override
  @Transactional
  public void logout(UUID userId) {
    if (userId != null) {
      LOGGER.debug("Processing session logout for userId={}", userId);
      Optional<UserEntity> userOptional = userRepository.findById(userId);

      if (userOptional.isPresent()) {
        UserEntity userEntity = userOptional.get();
        userEntity.setTokenId(null);
        userEntity.setTokenExpiresAt(null);
        userRepository.save(userEntity);
        LOGGER.info("Terminated active session for userId={}", userId);
      } else {
        LOGGER.warn("Logout failed: user not found for userId={}", userId);
        throw new IllegalStateException("User not found for session termination.");
      }
    } else {
      LOGGER.warn("Logout rejected: userId was null.");
      throw new IllegalArgumentException("User identifier cannot be null.");
    }
  }
}
