package com.anony.domain.coach;

import com.anony.domain.security.PasswordService;
import com.anony.persistence.entities.CoachDomainEntity;
import com.anony.persistence.entities.CoachEntity;
import com.anony.persistence.entities.DomainEntity;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.CoachDomainRepository;
import com.anony.persistence.repositories.CoachRepository;
import com.anony.persistence.repositories.DomainRepository;
import com.anony.persistence.repositories.UserRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Default implementation of {@link CoachService} handling coach profile persistence,
 * credential mapping, and verification state retrieval.
 */
@Service
public class DefaultCoachService implements CoachService {

  private final UserRepository userRepository;
  private final CoachRepository coachRepository;
  private final DomainRepository domainRepository;
  private final CoachDomainRepository coachDomainRepository;
  private final PasswordService passwordService;

  /**
   * Constructs coach service with required dependencies.
   *
   * @param userRepository repository for managing user identities
   * @param coachRepository repository for managing coach profiles
   * @param domainRepository repository for domain lookups
   * @param coachDomainRepository repository for coach-domain mappings
   * @param passwordService service for hashing passwords
   */
  public DefaultCoachService(
      UserRepository userRepository,
      CoachRepository coachRepository,
      DomainRepository domainRepository,
      CoachDomainRepository coachDomainRepository,
      PasswordService passwordService) {
    this.userRepository = userRepository;
    this.coachRepository = coachRepository;
    this.domainRepository = domainRepository;
    this.coachDomainRepository = coachDomainRepository;
    this.passwordService = passwordService;
  }

  @Override
  @Transactional
  public CoachProfileDetails registerCoach(CoachRegistrationCommand coachRegistrationCommand) {
    if (coachRegistrationCommand != null) {
      String email = coachRegistrationCommand.email();
      String rawPassword = coachRegistrationCommand.password();
      String firstName = coachRegistrationCommand.firstName();
      String lastName = coachRegistrationCommand.lastName();
      String icfLevel = coachRegistrationCommand.icfLevel();
      String timezone = coachRegistrationCommand.timezone();

      if (StringUtils.isNotBlank(email)
          && StringUtils.isNotBlank(rawPassword)
          && StringUtils.isNotBlank(firstName)
          && StringUtils.isNotBlank(lastName)
          && StringUtils.isNotBlank(icfLevel)
          && StringUtils.isNotBlank(timezone)) {

        if (rawPassword.length() > 8 && rawPassword.length() <= 32) {
          Optional<UserEntity> existingUser = userRepository.findByEmailIgnoreCase(email.trim());

          if (existingUser.isEmpty()) {
            boolean isAcc = "ACC".equalsIgnoreCase(icfLevel.trim());
            boolean isPcc = "PCC".equalsIgnoreCase(icfLevel.trim());
            boolean isMcc = "MCC".equalsIgnoreCase(icfLevel.trim());
            boolean isActc = "ACTC".equalsIgnoreCase(icfLevel.trim());

            if (isAcc || isPcc || isMcc || isActc) {
              UserEntity userEntity = new UserEntity();
              userEntity.setEmail(email.trim().toLowerCase(Locale.ROOT));
              userEntity.setPasswordHash(passwordService.hashPassword(rawPassword));
              userEntity.setRole(UserRole.COACH);
              UserEntity savedUserEntity = userRepository.save(userEntity);

              CoachEntity coachEntity = new CoachEntity();
              coachEntity.setUser(savedUserEntity);
              coachEntity.setFirstName(firstName.trim());
              coachEntity.setLastName(lastName.trim());
              coachEntity.setTimezone(timezone.trim());
              coachEntity.setBiography(coachRegistrationCommand.biography());
              coachEntity.setIcfAcc(isAcc);
              coachEntity.setIcfPcc(isPcc);
              coachEntity.setIcfMcc(isMcc);
              coachEntity.setIcfActc(isActc);

              String formattedDetails = formatCredentialDetails(
                  coachRegistrationCommand.credentialDetails(),
                  coachRegistrationCommand.hourlyRate());
              coachEntity.setCredentialDetails(formattedDetails);
              coachEntity.setVerified(false);
              coachEntity.setOnboarded(false);

              CoachEntity savedCoachEntity = coachRepository.save(coachEntity);

              List<String> assignedDomainCodes = new ArrayList<>();
              if (coachRegistrationCommand.domainCodes() != null) {
                for (String domainCode : coachRegistrationCommand.domainCodes()) {
                  if (StringUtils.isNotBlank(domainCode)) {
                    Optional<DomainEntity> domainEntityOptional =
                        domainRepository.findByCodeIgnoreCase(domainCode.trim());
                    if (domainEntityOptional.isPresent()) {
                      CoachDomainEntity coachDomainEntity = new CoachDomainEntity();
                      coachDomainEntity.setCoach(savedCoachEntity);
                      coachDomainEntity.setDomain(domainEntityOptional.get());
                      coachDomainRepository.save(coachDomainEntity);
                      assignedDomainCodes.add(domainEntityOptional.get().getCode());
                    } else {
                      assignedDomainCodes.add(domainCode.trim().toUpperCase(Locale.ROOT));
                    }
                  }
                }
              }

              return toCoachProfileDetails(savedCoachEntity, savedUserEntity, assignedDomainCodes);
            } else {
              throw new IllegalArgumentException(
                  "Invalid ICF credential level: must be ACC, PCC, MCC, or ACTC.");
            }
          } else {
            throw new IllegalArgumentException("Email is already registered: " + email);
          }
        } else {
          throw new IllegalArgumentException(
              "Password must be between 9 and 32 characters in length.");
        }
      } else {
        throw new IllegalArgumentException(
            "Email, password, first name, last name, ICF level, and timezone cannot be blank.");
      }
    } else {
      throw new IllegalArgumentException("Coach registration command cannot be null.");
    }
  }

  @Override
  @Transactional(readOnly = true)
  public CoachProfileDetails getCoachProfileByUserId(UUID userId) {
    if (userId != null) {
      Optional<CoachEntity> coachOptional = coachRepository.findByUser_UserId(userId);

      if (coachOptional.isPresent()) {
        CoachEntity coachEntity = coachOptional.get();
        List<CoachDomainEntity> coachDomains =
            coachDomainRepository.findByCoach_CoachId(coachEntity.getCoachId());

        List<String> domainCodes = new ArrayList<>();
        for (CoachDomainEntity coachDomainEntity : coachDomains) {
          domainCodes.add(coachDomainEntity.getDomain().getCode());
        }

        return toCoachProfileDetails(coachEntity, coachEntity.getUser(), domainCodes);
      } else {
        throw new IllegalStateException("Coach profile not found for user identifier: " + userId);
      }
    } else {
      throw new IllegalArgumentException("User identifier cannot be null.");
    }
  }

  private String formatCredentialDetails(String credentialDetails, java.math.BigDecimal hourlyRate) {
    StringBuilder stringBuilder = new StringBuilder();
    if (StringUtils.isNotBlank(credentialDetails)) {
      stringBuilder.append(credentialDetails.trim());
    }
    if (hourlyRate != null) {
      if (stringBuilder.length() > 0) {
        stringBuilder.append(" | Hourly Rate: $").append(hourlyRate);
      } else {
        stringBuilder.append("Hourly Rate: $").append(hourlyRate);
      }
    }
    return stringBuilder.toString();
  }

  private CoachProfileDetails toCoachProfileDetails(
      CoachEntity coachEntity, UserEntity userEntity, List<String> domainCodes) {
    String icfLevel = "ACC";
    if (Boolean.TRUE.equals(coachEntity.getIcfMcc())) {
      icfLevel = "MCC";
    } else if (Boolean.TRUE.equals(coachEntity.getIcfPcc())) {
      icfLevel = "PCC";
    } else if (Boolean.TRUE.equals(coachEntity.getIcfActc())) {
      icfLevel = "ACTC";
    }

    return new CoachProfileDetails(
        coachEntity.getCoachId(),
        userEntity.getUserId(),
        userEntity.getEmail(),
        coachEntity.getFirstName(),
        coachEntity.getLastName(),
        coachEntity.getTimezone(),
        coachEntity.getBiography(),
        icfLevel,
        coachEntity.getIcfAcc(),
        coachEntity.getIcfPcc(),
        coachEntity.getIcfMcc(),
        coachEntity.getIcfActc(),
        coachEntity.getCredentialDetails(),
        coachEntity.getVerified(),
        coachEntity.getOnboarded(),
        domainCodes,
        coachEntity.getCreatedAt());
  }
}
