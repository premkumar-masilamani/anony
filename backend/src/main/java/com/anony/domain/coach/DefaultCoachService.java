package com.anony.domain.coach;

import com.anony.domain.security.PasswordService;
import com.anony.persistence.entities.CoachDomainEntity;
import com.anony.persistence.entities.CoachEntity;
import com.anony.persistence.entities.DomainEntity;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.Gender;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.CoachDomainRepository;
import com.anony.persistence.repositories.CoachRepository;
import com.anony.persistence.repositories.DomainRepository;
import com.anony.persistence.repositories.UserRepository;
import java.math.BigDecimal;
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
 * credential mapping, updates, and verification state retrieval.
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
      String timezone = coachRegistrationCommand.timezone();

      if (StringUtils.isNotBlank(email)) {
        if (StringUtils.isNotBlank(rawPassword)) {
          if (StringUtils.isNotBlank(firstName)) {
            if (StringUtils.isNotBlank(lastName)) {
              if (StringUtils.isNotBlank(timezone)) {
                if (rawPassword.length() > 8 && rawPassword.length() <= 32) {
                  Optional<UserEntity> existingUser =
                      userRepository.findByEmailIgnoreCase(email.trim());

                  if (existingUser.isEmpty()) {
                    boolean[] credentials = resolveCredentials(
                        coachRegistrationCommand.icfAcc(),
                        coachRegistrationCommand.icfPcc(),
                        coachRegistrationCommand.icfMcc(),
                        coachRegistrationCommand.icfActc(),
                        coachRegistrationCommand.icfLevel());

                    if (hasAnyCredential(credentials)) {
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
                      coachEntity.setIcfAcc(credentials[0]);
                      coachEntity.setIcfPcc(credentials[1]);
                      coachEntity.setIcfMcc(credentials[2]);
                      coachEntity.setIcfActc(credentials[3]);

                      applyOptionalProfileFields(
                          coachEntity,
                          coachRegistrationCommand.photoUrl(),
                          coachRegistrationCommand.gender(),
                          coachRegistrationCommand.countryCode());

                      String formattedDetails = formatCredentialDetails(
                          coachRegistrationCommand.credentialDetails(),
                          coachRegistrationCommand.hourlyRate());
                      coachEntity.setCredentialDetails(formattedDetails);
                      coachEntity.setVerified(false);
                      coachEntity.setOnboarded(false);

                      CoachEntity savedCoachEntity = coachRepository.save(coachEntity);
                      List<String> assignedDomainCodes =
                          saveCoachDomains(savedCoachEntity, coachRegistrationCommand.domainCodes());

                      return toCoachProfileDetails(
                          savedCoachEntity, savedUserEntity, assignedDomainCodes);
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
                throw new IllegalArgumentException("Timezone cannot be blank.");
              }
            } else {
              throw new IllegalArgumentException("Last name cannot be blank.");
            }
          } else {
            throw new IllegalArgumentException("First name cannot be blank.");
          }
        } else {
          throw new IllegalArgumentException("Password cannot be blank.");
        }
      } else {
        throw new IllegalArgumentException("Email cannot be blank.");
      }
    } else {
      throw new IllegalArgumentException("Coach registration command cannot be null.");
    }
  }

  @Override
  @Transactional
  public CoachProfileDetails updateCoachProfile(
      UUID userId, CoachUpdateCommand coachUpdateCommand) {
    if (userId != null) {
      if (coachUpdateCommand != null) {
        String firstName = coachUpdateCommand.firstName();
        String lastName = coachUpdateCommand.lastName();
        String timezone = coachUpdateCommand.timezone();

        if (StringUtils.isNotBlank(firstName)) {
          if (StringUtils.isNotBlank(lastName)) {
            if (StringUtils.isNotBlank(timezone)) {
              Optional<CoachEntity> coachOptional = coachRepository.findByUser_UserId(userId);

              if (coachOptional.isPresent()) {
                CoachEntity coachEntity = coachOptional.get();

                boolean[] credentials = resolveCredentials(
                    coachUpdateCommand.icfAcc(),
                    coachUpdateCommand.icfPcc(),
                    coachUpdateCommand.icfMcc(),
                    coachUpdateCommand.icfActc(),
                    coachUpdateCommand.icfLevel());

                if (hasAnyCredential(credentials)) {
                  coachEntity.setFirstName(firstName.trim());
                  coachEntity.setLastName(lastName.trim());
                  coachEntity.setTimezone(timezone.trim());
                  coachEntity.setBiography(coachUpdateCommand.biography());
                  coachEntity.setIcfAcc(credentials[0]);
                  coachEntity.setIcfPcc(credentials[1]);
                  coachEntity.setIcfMcc(credentials[2]);
                  coachEntity.setIcfActc(credentials[3]);

                  applyOptionalProfileFields(
                      coachEntity,
                      coachUpdateCommand.photoUrl(),
                      coachUpdateCommand.gender(),
                      coachUpdateCommand.countryCode());

                  String formattedDetails = formatCredentialDetails(
                      coachUpdateCommand.credentialDetails(),
                      coachUpdateCommand.hourlyRate());
                  coachEntity.setCredentialDetails(formattedDetails);

                  CoachEntity updatedCoachEntity = coachRepository.save(coachEntity);

                  List<CoachDomainEntity> existingDomains =
                      coachDomainRepository.findByCoach_CoachId(updatedCoachEntity.getCoachId());
                  coachDomainRepository.deleteAll(existingDomains);
                  coachDomainRepository.flush();

                  List<String> assignedDomainCodes =
                      saveCoachDomains(updatedCoachEntity, coachUpdateCommand.domainCodes());

                  return toCoachProfileDetails(
                      updatedCoachEntity, updatedCoachEntity.getUser(), assignedDomainCodes);
                } else {
                  throw new IllegalArgumentException(
                      "Invalid ICF credential level: must be ACC, PCC, MCC, or ACTC.");
                }
              } else {
                throw new IllegalStateException(
                    "Coach profile not found for user identifier: " + userId);
              }
            } else {
              throw new IllegalArgumentException("Timezone cannot be blank.");
            }
          } else {
            throw new IllegalArgumentException("Last name cannot be blank.");
          }
        } else {
          throw new IllegalArgumentException("First name cannot be blank.");
        }
      } else {
        throw new IllegalArgumentException("Coach update command cannot be null.");
      }
    } else {
      throw new IllegalArgumentException("User identifier cannot be null.");
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

  private boolean hasAnyCredential(boolean... credentials) {
    for (boolean credential : credentials) {
      if (credential) {
        return true;
      }
    }
    return false;
  }

  private boolean[] resolveCredentials(
      Boolean acc, Boolean pcc, Boolean mcc, Boolean actc, String level) {
    boolean isAcc = Boolean.TRUE.equals(acc);
    boolean isPcc = Boolean.TRUE.equals(pcc);
    boolean isMcc = Boolean.TRUE.equals(mcc);
    boolean isActc = Boolean.TRUE.equals(actc);

    boolean[] result = {isAcc, isPcc, isMcc, isActc};
    if (hasAnyCredential(result)) {
      return result;
    } else {
      if (StringUtils.isNotBlank(level)) {
        String trimmed = level.trim();
        if ("ACC".equalsIgnoreCase(trimmed)) {
          return new boolean[] {true, false, false, false};
        } else if ("PCC".equalsIgnoreCase(trimmed)) {
          return new boolean[] {false, true, false, false};
        } else if ("MCC".equalsIgnoreCase(trimmed)) {
          return new boolean[] {false, false, true, false};
        } else if ("ACTC".equalsIgnoreCase(trimmed)) {
          return new boolean[] {false, false, false, true};
        } else {
          return new boolean[] {false, false, false, false};
        }
      } else {
        return new boolean[] {false, false, false, false};
      }
    }
  }

  private void applyOptionalProfileFields(
      CoachEntity coachEntity, String photoUrl, String gender, String countryCode) {
    if (StringUtils.isNotBlank(photoUrl)) {
      coachEntity.setPhotoUrl(photoUrl.trim());
    } else {
      coachEntity.setPhotoUrl(null);
    }

    if (StringUtils.isNotBlank(gender)) {
      try {
        coachEntity.setGender(Gender.valueOf(gender.trim().toUpperCase(Locale.ROOT)));
      } catch (IllegalArgumentException e) {
        coachEntity.setGender(null);
      }
    } else {
      coachEntity.setGender(null);
    }

    if (StringUtils.isNotBlank(countryCode)) {
      String upperCountry = countryCode.trim().toUpperCase(Locale.ROOT);
      if (upperCountry.matches("^[A-Z]{2}$")) {
        coachEntity.setCountryCode(upperCountry);
      } else {
        coachEntity.setCountryCode(null);
      }
    } else {
      coachEntity.setCountryCode(null);
    }
  }

  private List<String> saveCoachDomains(CoachEntity coachEntity, List<String> domainCodes) {
    List<String> assignedDomainCodes = new ArrayList<>();
    if (domainCodes != null) {
      for (String domainCode : domainCodes) {
        if (StringUtils.isNotBlank(domainCode)) {
          Optional<DomainEntity> domainEntityOptional =
              domainRepository.findByCodeIgnoreCase(domainCode.trim());
          DomainEntity domainEntity;
          if (domainEntityOptional.isPresent()) {
            domainEntity = domainEntityOptional.get();
          } else {
            DomainEntity newDomain = new DomainEntity();
            String formattedCode =
                domainCode.trim().toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9_]+", "_");
            if (formattedCode.length() > 40) {
              formattedCode = formattedCode.substring(0, 40);
            }
            newDomain.setCode(formattedCode);
            newDomain.setName(domainCode.trim());
            DomainEntity saved = domainRepository.save(newDomain);
            domainEntity = saved != null ? saved : newDomain;
          }
          CoachDomainEntity coachDomainEntity = new CoachDomainEntity();
          coachDomainEntity.setCoach(coachEntity);
          coachDomainEntity.setDomain(domainEntity);
          coachDomainRepository.save(coachDomainEntity);
          assignedDomainCodes.add(domainEntity.getCode());
        }
      }
    }
    return assignedDomainCodes;
  }

  private String formatCredentialDetails(String credentialDetails, BigDecimal hourlyRate) {
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

  private BigDecimal extractHourlyRate(String credentialDetails) {
    if (StringUtils.isNotBlank(credentialDetails)) {
      int markerIndex = credentialDetails.indexOf("Hourly Rate: $");
      if (markerIndex >= 0) {
        String rateString =
            credentialDetails.substring(markerIndex + "Hourly Rate: $".length()).trim();
        int spaceIndex = rateString.indexOf(' ');
        String cleanRate;
        if (spaceIndex > 0) {
          cleanRate = rateString.substring(0, spaceIndex);
        } else {
          cleanRate = rateString;
        }
        try {
          return new BigDecimal(cleanRate);
        } catch (NumberFormatException e) {
          return null;
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
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

    BigDecimal hourlyRate = extractHourlyRate(coachEntity.getCredentialDetails());
    String genderString = coachEntity.getGender() != null ? coachEntity.getGender().name() : null;

    return new CoachProfileDetails(
        coachEntity.getCoachId(),
        userEntity.getUserId(),
        userEntity.getEmail(),
        coachEntity.getFirstName(),
        coachEntity.getLastName(),
        coachEntity.getPhotoUrl(),
        genderString,
        coachEntity.getCountryCode(),
        coachEntity.getTimezone(),
        coachEntity.getBiography(),
        icfLevel,
        coachEntity.getIcfAcc(),
        coachEntity.getIcfPcc(),
        coachEntity.getIcfMcc(),
        coachEntity.getIcfActc(),
        coachEntity.getCredentialDetails(),
        hourlyRate,
        coachEntity.getVerified(),
        coachEntity.getOnboarded(),
        domainCodes,
        coachEntity.getCreatedAt());
  }
}
