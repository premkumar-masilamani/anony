package com.anony.domain.client;

import com.anony.domain.security.PasswordService;
import com.anony.persistence.entities.ClientEntity;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.ClientRepository;
import com.anony.persistence.repositories.UserRepository;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Default implementation of {@link ClientService} handling client registration, profile lookups,
 * and privacy mode updates.
 */
@Service
public class DefaultClientService implements ClientService {

  private static final Logger LOGGER = LoggerFactory.getLogger(DefaultClientService.class);

  private final UserRepository userRepository;
  private final ClientRepository clientRepository;
  private final PasswordService passwordService;
  private final ProceduralAliasGenerator proceduralAliasGenerator = new ProceduralAliasGenerator();

  /**
   * Constructs client service with required dependencies.
   *
   * @param userRepository repository for managing user identities
   * @param clientRepository repository for managing client profiles
   * @param passwordService service for hashing passwords
   */
  public DefaultClientService(
      UserRepository userRepository,
      ClientRepository clientRepository,
      PasswordService passwordService) {
    this.userRepository = userRepository;
    this.clientRepository = clientRepository;
    this.passwordService = passwordService;
  }

  @Override
  @Transactional
  public ClientProfileDetails registerClient(ClientRegistrationCommand clientRegistrationCommand) {
    if (clientRegistrationCommand != null) {
      String email = clientRegistrationCommand.email();
      String rawPassword = clientRegistrationCommand.password();

      if (StringUtils.isNotBlank(email) && StringUtils.isNotBlank(rawPassword)) {
        if (rawPassword.length() > 8 && rawPassword.length() <= 32) {
          LOGGER.debug("Registering new client account for email={}", email);
          Optional<UserEntity> existingUser = userRepository.findByEmailIgnoreCase(email.trim());

          if (existingUser.isEmpty()) {
            UserEntity userEntity = new UserEntity();
            userEntity.setEmail(email.trim().toLowerCase(Locale.ROOT));
            userEntity.setPasswordHash(passwordService.hashPassword(rawPassword));
            userEntity.setRole(UserRole.CLIENT);
            UserEntity savedUserEntity = userRepository.save(userEntity);

            String firstName = StringUtils.isNotBlank(clientRegistrationCommand.firstName())
                ? clientRegistrationCommand.firstName().trim()
                : "Anonymous";
            String lastName = StringUtils.isNotBlank(clientRegistrationCommand.lastName())
                ? clientRegistrationCommand.lastName().trim()
                : "Client";
            String alias = StringUtils.isNotBlank(clientRegistrationCommand.alias())
                ? clientRegistrationCommand.alias().trim()
                : proceduralAliasGenerator.generateAlias();

            ClientEntity clientEntity = new ClientEntity();
            clientEntity.setUser(savedUserEntity);
            clientEntity.setFirstName(firstName);
            clientEntity.setLastName(lastName);
            clientEntity.setAlias(alias);
            clientEntity.setAnonymous(true);
            clientEntity.setOnboarded(false);
            clientEntity.setAnonymousMode(true);
            clientEntity.setFreeSessionsCount(0);
            clientEntity.setLastFreeSessionAt(null);

            ClientEntity savedClientEntity = clientRepository.save(clientEntity);

            LOGGER.info(
                "Registered clientId={} (userId={}, alias={}) for email={}",
                savedClientEntity.getClientId(),
                savedUserEntity.getUserId(),
                alias,
                savedUserEntity.getEmail());

            return toClientProfileDetails(savedClientEntity, savedUserEntity);
          } else {
            LOGGER.warn("Client registration rejected: email already registered ({})", email);
            throw new IllegalArgumentException("Email is already registered: " + email);
          }
        } else {
          LOGGER.warn("Client registration rejected: invalid password length for email={}", email);
          throw new IllegalArgumentException(
              "Password must be between 9 and 32 characters in length.");
        }
      } else {
        LOGGER.warn("Client registration rejected: email or password was blank.");
        throw new IllegalArgumentException("Email and password cannot be blank.");
      }
    } else {
      LOGGER.warn("Client registration rejected: command was null.");
      throw new IllegalArgumentException("Client registration command cannot be null.");
    }
  }

  @Override
  @Transactional(readOnly = true)
  public ClientProfileDetails getClientProfileByUserId(UUID userId) {
    if (userId != null) {
      LOGGER.debug("Fetching client profile for userId={}", userId);
      Optional<ClientEntity> clientOptional = clientRepository.findByUser_UserId(userId);

      if (clientOptional.isPresent()) {
        ClientEntity clientEntity = clientOptional.get();
        LOGGER.debug(
            "Found clientId={} (alias={}) for userId={}",
            clientEntity.getClientId(),
            clientEntity.getAlias(),
            userId);
        return toClientProfileDetails(clientEntity, clientEntity.getUser());
      } else {
        LOGGER.warn("Client profile not found for userId={}", userId);
        throw new IllegalStateException("Client profile not found for user identifier: " + userId);
      }
    } else {
      LOGGER.warn("Client profile lookup rejected: userId was null.");
      throw new IllegalArgumentException("User identifier cannot be null.");
    }
  }

  @Override
  @Transactional
  public ClientProfileDetails updatePrivacyMode(UUID userId, boolean isAnonymousMode) {
    if (userId != null) {
      LOGGER.debug("Updating privacy mode for userId={} to isAnonymousMode={}", userId, isAnonymousMode);
      Optional<ClientEntity> clientOptional = clientRepository.findByUser_UserId(userId);

      if (clientOptional.isPresent()) {
        ClientEntity clientEntity = clientOptional.get();
        clientEntity.setAnonymousMode(isAnonymousMode);
        ClientEntity updatedClientEntity = clientRepository.save(clientEntity);
        LOGGER.info(
            "Updated privacy mode for clientId={} (userId={}) to isAnonymousMode={}",
            updatedClientEntity.getClientId(),
            userId,
            isAnonymousMode);
        return toClientProfileDetails(updatedClientEntity, updatedClientEntity.getUser());
      } else {
        LOGGER.warn("Privacy mode update failed: client profile not found for userId={}", userId);
        throw new IllegalStateException("Client profile not found for user identifier: " + userId);
      }
    } else {
      LOGGER.warn("Privacy mode update rejected: userId was null.");
      throw new IllegalArgumentException("User identifier cannot be null.");
    }
  }

  private ClientProfileDetails toClientProfileDetails(
      ClientEntity clientEntity, UserEntity userEntity) {
    return new ClientProfileDetails(
        clientEntity.getClientId(),
        userEntity.getUserId(),
        userEntity.getEmail(),
        clientEntity.getFirstName(),
        clientEntity.getLastName(),
        clientEntity.getAlias(),
        clientEntity.getAnonymous(),
        clientEntity.getOnboarded(),
        clientEntity.getAnonymousMode(),
        clientEntity.getFreeSessionsCount(),
        clientEntity.getLastFreeSessionAt(),
        clientEntity.getCreatedAt());
  }
}
