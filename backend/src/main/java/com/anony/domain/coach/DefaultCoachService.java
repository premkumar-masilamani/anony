package com.anony.domain.coach;

import com.anony.domain.security.PasswordService;
import com.anony.persistence.entities.AvailabilityTemplateEntity;
import com.anony.persistence.entities.AvailabilityWindowEntity;
import com.anony.persistence.entities.CoachDomainEntity;
import com.anony.persistence.entities.CoachEntity;
import com.anony.persistence.entities.DomainEntity;
import com.anony.persistence.entities.SlotEntity;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.Gender;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.AvailabilityTemplateRepository;
import com.anony.persistence.repositories.AvailabilityWindowRepository;
import com.anony.persistence.repositories.CoachDomainRepository;
import com.anony.persistence.repositories.CoachRepository;
import com.anony.persistence.repositories.DomainRepository;
import com.anony.persistence.repositories.SlotRepository;
import com.anony.persistence.repositories.UserRepository;
import java.math.BigDecimal;
import java.time.DateTimeException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
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
 * credential mapping, updates, verification state retrieval, and rolling 30-day availability generation.
 */
@Service
public class DefaultCoachService implements CoachService {

  private static final int SLOT_DURATION_THIRTY_MINUTES = 30;
  private static final int SLOT_DURATION_SIXTY_MINUTES = 60;
  private static final int ROLLING_AVAILABILITY_DAYS = 30;
  private static final int DAYS_IN_WEEK = 7;
  private static final long MANDATORY_MONTHLY_FREE_PLEDGE_MINUTES = 60L;
  private static final long DEFAULT_DISCOVERY_WINDOW_DAYS = 30L;
  private static final LocalTime DEFAULT_MORNING_WINDOW_START = LocalTime.of(9, 0);
  private static final LocalTime DEFAULT_MORNING_WINDOW_END = LocalTime.of(12, 0);
  private static final LocalTime DEFAULT_AFTERNOON_WINDOW_START = LocalTime.of(14, 0);
  private static final LocalTime DEFAULT_AFTERNOON_WINDOW_END = LocalTime.of(17, 0);

  private final UserRepository userRepository;
  private final CoachRepository coachRepository;
  private final DomainRepository domainRepository;
  private final CoachDomainRepository coachDomainRepository;
  private final AvailabilityTemplateRepository availabilityTemplateRepository;
  private final AvailabilityWindowRepository availabilityWindowRepository;
  private final SlotRepository slotRepository;
  private final PasswordService passwordService;

  /**
   * Constructs coach service with required dependencies.
   *
   * @param userRepository repository for managing user identities
   * @param coachRepository repository for managing coach profiles
   * @param domainRepository repository for domain lookups
   * @param coachDomainRepository repository for coach-domain mappings
   * @param availabilityTemplateRepository repository for coach availability templates
   * @param availabilityWindowRepository repository for weekly availability windows
   * @param slotRepository repository for concrete availability slots
   * @param passwordService service for hashing passwords
   */
  public DefaultCoachService(
      UserRepository userRepository,
      CoachRepository coachRepository,
      DomainRepository domainRepository,
      CoachDomainRepository coachDomainRepository,
      AvailabilityTemplateRepository availabilityTemplateRepository,
      AvailabilityWindowRepository availabilityWindowRepository,
      SlotRepository slotRepository,
      PasswordService passwordService) {
    this.userRepository = userRepository;
    this.coachRepository = coachRepository;
    this.domainRepository = domainRepository;
    this.coachDomainRepository = coachDomainRepository;
    this.availabilityTemplateRepository = availabilityTemplateRepository;
    this.availabilityWindowRepository = availabilityWindowRepository;
    this.slotRepository = slotRepository;
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

  @Override
  @Transactional
  public int generateUpcomingAvailabilitiesForAllCoaches() {
    List<CoachEntity> allCoaches = coachRepository.findAll();
    int totalCreatedSlots = 0;

    for (CoachEntity coachEntity : allCoaches) {
      totalCreatedSlots += generateThirtyDaySlotsForCoach(coachEntity);
    }

    return totalCreatedSlots;
  }

  @Override
  @Transactional(readOnly = true)
  public List<CoachAvailabilitySlotDetails> getCoachAvailabilities(
      UUID coachId, Instant from, Instant to) {
    if (coachId != null) {
      Optional<CoachEntity> coachOptional = coachRepository.findById(coachId);

      if (coachOptional.isPresent()) {
        Instant effectiveFrom = from != null ? from : Instant.now();
        Instant effectiveTo =
            to != null
                ? to
                : effectiveFrom.plus(Duration.ofDays(DEFAULT_DISCOVERY_WINDOW_DAYS));

        if (!effectiveTo.isBefore(effectiveFrom)) {
          List<SlotEntity> availableSlotEntities =
              slotRepository.findAvailableSlotsByCoachInWindow(
                  coachId, effectiveFrom, effectiveTo);

          List<CoachAvailabilitySlotDetails> availableSlots = new ArrayList<>();
          for (SlotEntity slotEntity : availableSlotEntities) {
            availableSlots.add(toSlotDetails(slotEntity, coachId, false));
          }

          return availableSlots;
        } else {
          throw new IllegalArgumentException(
              "End timestamp must not be before start timestamp.");
        }
      } else {
        throw new IllegalStateException(
            "Coach profile not found for coach identifier: " + coachId);
      }
    } else {
      throw new IllegalArgumentException("Coach identifier cannot be null.");
    }
  }

  private int generateThirtyDaySlotsForCoach(CoachEntity coachEntity) {
    ZoneId coachZoneId = resolveCoachZoneId(coachEntity.getTimezone());
    AvailabilityTemplateEntity availabilityTemplate =
        resolveOrCreateAvailabilityTemplate(coachEntity);
    int slotDurationMinutes = normalizeSlotDuration(availabilityTemplate.getSlotDurationMinutes());

    List<AvailabilityWindowEntity> weeklyWindows =
        resolveOrCreateAvailabilityWindows(availabilityTemplate);

    LocalDate startDate = LocalDate.now(coachZoneId);
    Instant rangeStartUtc =
        startDate.minusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
    Instant rangeEndUtc =
        startDate.plusDays(ROLLING_AVAILABILITY_DAYS + 2L).atStartOfDay(ZoneOffset.UTC).toInstant();

    List<SlotEntity> existingSlots =
        new ArrayList<>(
            slotRepository
                .findByAvailabilityTemplate_AvailabilityTemplateIdAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(
                    availabilityTemplate.getAvailabilityTemplateId(), rangeStartUtc, rangeEndUtc));

    int createdSlotsCount = 0;
    for (int dayOffset = 0; dayOffset < ROLLING_AVAILABILITY_DAYS; dayOffset++) {
      LocalDate targetDate = startDate.plusDays(dayOffset);
      short isoDayOfWeek = (short) targetDate.getDayOfWeek().getValue();

      for (AvailabilityWindowEntity windowEntity : weeklyWindows) {
        if (windowEntity.getDayOfWeek() != null
            && windowEntity.getDayOfWeek() == isoDayOfWeek) {
          createdSlotsCount +=
              generateSlotsForWindowOnDate(
                  availabilityTemplate,
                  windowEntity,
                  targetDate,
                  coachZoneId,
                  slotDurationMinutes,
                  existingSlots);
        }
      }
    }

    return createdSlotsCount;
  }

  private int generateSlotsForWindowOnDate(
      AvailabilityTemplateEntity availabilityTemplate,
      AvailabilityWindowEntity windowEntity,
      LocalDate targetDate,
      ZoneId coachZoneId,
      int slotDurationMinutes,
      List<SlotEntity> existingSlots) {
    LocalTime windowStart = windowEntity.getStartTime();
    LocalTime windowEnd = windowEntity.getEndTime();
    int createdCount = 0;

    LocalTime cursorTime = windowStart;
    while (!cursorTime.plusMinutes(slotDurationMinutes).isAfter(windowEnd)) {
      LocalTime slotLocalEnd = cursorTime.plusMinutes(slotDurationMinutes);
      Instant slotStartUtc = ZonedDateTime.of(targetDate, cursorTime, coachZoneId).toInstant();
      Instant slotEndUtc = ZonedDateTime.of(targetDate, slotLocalEnd, coachZoneId).toInstant();

      if (!overlapsAnyExistingSlot(slotStartUtc, slotEndUtc, existingSlots)) {
        YearMonth slotYearMonth = YearMonth.from(slotStartUtc.atZone(ZoneOffset.UTC));
        long currentMonthlyFreePledgeMinutes =
            calculateFreePledgeMinutesForMonth(slotYearMonth, existingSlots);
        boolean shouldMarkAsFreePledge =
            currentMonthlyFreePledgeMinutes < MANDATORY_MONTHLY_FREE_PLEDGE_MINUTES;

        SlotEntity newSlotEntity = new SlotEntity();
        newSlotEntity.setAvailabilityTemplate(availabilityTemplate);
        newSlotEntity.setStartAt(slotStartUtc);
        newSlotEntity.setEndAt(slotEndUtc);
        newSlotEntity.setFreePledge(shouldMarkAsFreePledge);

        SlotEntity savedSlot = slotRepository.save(newSlotEntity);
        SlotEntity persistedSlot = savedSlot != null ? savedSlot : newSlotEntity;
        existingSlots.add(persistedSlot);
        createdCount++;
      }

      cursorTime = slotLocalEnd;
    }

    return createdCount;
  }

  private boolean overlapsAnyExistingSlot(
      Instant candidateStart, Instant candidateEnd, List<SlotEntity> existingSlots) {
    for (SlotEntity existingSlot : existingSlots) {
      boolean nonOverlapping =
          !candidateStart.isBefore(existingSlot.getEndAt())
              || !existingSlot.getStartAt().isBefore(candidateEnd);
      if (nonOverlapping) {
        continue;
      } else {
        return true;
      }
    }
    return false;
  }

  private long calculateFreePledgeMinutesForMonth(
      YearMonth targetMonth, List<SlotEntity> existingSlots) {
    long totalFreePledgeMinutes = 0L;
    for (SlotEntity existingSlot : existingSlots) {
      YearMonth slotMonth = YearMonth.from(existingSlot.getStartAt().atZone(ZoneOffset.UTC));
      if (slotMonth.equals(targetMonth) && Boolean.TRUE.equals(existingSlot.getFreePledge())) {
        totalFreePledgeMinutes +=
            Duration.between(existingSlot.getStartAt(), existingSlot.getEndAt()).toMinutes();
      }
    }
    return totalFreePledgeMinutes;
  }

  private ZoneId resolveCoachZoneId(String timezone) {
    if (StringUtils.isNotBlank(timezone)) {
      try {
        return ZoneId.of(timezone.trim());
      } catch (DateTimeException dateTimeException) {
        return ZoneOffset.UTC;
      }
    } else {
      return ZoneOffset.UTC;
    }
  }

  private int normalizeSlotDuration(Short slotDurationMinutes) {
    if (slotDurationMinutes != null && slotDurationMinutes == SLOT_DURATION_THIRTY_MINUTES) {
      return SLOT_DURATION_THIRTY_MINUTES;
    } else {
      return SLOT_DURATION_SIXTY_MINUTES;
    }
  }

  private AvailabilityTemplateEntity resolveOrCreateAvailabilityTemplate(
      CoachEntity coachEntity) {
    Optional<AvailabilityTemplateEntity> existingTemplateOptional =
        availabilityTemplateRepository.findByCoach_CoachId(coachEntity.getCoachId());
    if (existingTemplateOptional.isPresent()) {
      AvailabilityTemplateEntity existingTemplate = existingTemplateOptional.get();
      if (Boolean.TRUE.equals(existingTemplate.getActive())) {
        return existingTemplate;
      } else {
        existingTemplate.setActive(true);
        AvailabilityTemplateEntity updated =
            availabilityTemplateRepository.save(existingTemplate);
        return updated != null ? updated : existingTemplate;
      }
    } else {
      AvailabilityTemplateEntity newTemplate = new AvailabilityTemplateEntity();
      newTemplate.setCoach(coachEntity);
      newTemplate.setSlotDurationMinutes((short) SLOT_DURATION_SIXTY_MINUTES);
      newTemplate.setActive(true);
      AvailabilityTemplateEntity saved = availabilityTemplateRepository.save(newTemplate);
      return saved != null ? saved : newTemplate;
    }
  }

  private List<AvailabilityWindowEntity> resolveOrCreateAvailabilityWindows(
      AvailabilityTemplateEntity availabilityTemplate) {
    List<AvailabilityWindowEntity> existingWindows =
        availabilityWindowRepository
            .findByAvailabilityTemplate_AvailabilityTemplateIdOrderByDayOfWeekAscStartTimeAsc(
                availabilityTemplate.getAvailabilityTemplateId());
    if (!existingWindows.isEmpty()) {
      return existingWindows;
    } else {
      List<AvailabilityWindowEntity> defaultWindows = new ArrayList<>();
      for (short dayOfWeek = 1; dayOfWeek <= DAYS_IN_WEEK; dayOfWeek++) {
        AvailabilityWindowEntity morningWindow = new AvailabilityWindowEntity();
        morningWindow.setAvailabilityTemplate(availabilityTemplate);
        morningWindow.setDayOfWeek(dayOfWeek);
        morningWindow.setStartTime(DEFAULT_MORNING_WINDOW_START);
        morningWindow.setEndTime(DEFAULT_MORNING_WINDOW_END);
        AvailabilityWindowEntity savedMorning =
            availabilityWindowRepository.save(morningWindow);
        defaultWindows.add(savedMorning != null ? savedMorning : morningWindow);

        AvailabilityWindowEntity afternoonWindow = new AvailabilityWindowEntity();
        afternoonWindow.setAvailabilityTemplate(availabilityTemplate);
        afternoonWindow.setDayOfWeek(dayOfWeek);
        afternoonWindow.setStartTime(DEFAULT_AFTERNOON_WINDOW_START);
        afternoonWindow.setEndTime(DEFAULT_AFTERNOON_WINDOW_END);
        AvailabilityWindowEntity savedAfternoon =
            availabilityWindowRepository.save(afternoonWindow);
        defaultWindows.add(savedAfternoon != null ? savedAfternoon : afternoonWindow);
      }
      return defaultWindows;
    }
  }

  private CoachAvailabilitySlotDetails toSlotDetails(
      SlotEntity slotEntity, UUID coachId, boolean isBooked) {
    int durationMinutes =
        (int) Duration.between(slotEntity.getStartAt(), slotEntity.getEndAt()).toMinutes();
    return new CoachAvailabilitySlotDetails(
        slotEntity.getSlotId(),
        coachId,
        slotEntity.getStartAt(),
        slotEntity.getEndAt(),
        durationMinutes,
        Boolean.TRUE.equals(slotEntity.getFreePledge()),
        isBooked);
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
