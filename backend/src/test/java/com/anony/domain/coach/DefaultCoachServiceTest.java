package com.anony.domain.coach;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DefaultCoachServiceTest {

  @Mock
  private UserRepository userRepository;

  @Mock
  private CoachRepository coachRepository;

  @Mock
  private DomainRepository domainRepository;

  @Mock
  private CoachDomainRepository coachDomainRepository;

  @Mock
  private AvailabilityTemplateRepository availabilityTemplateRepository;

  @Mock
  private AvailabilityWindowRepository availabilityWindowRepository;

  @Mock
  private SlotRepository slotRepository;

  @Mock
  private PasswordService passwordService;

  private DefaultCoachService coachService;

  @BeforeEach
  void setUp() {
    coachService =
        new DefaultCoachService(
            userRepository,
            coachRepository,
            domainRepository,
            coachDomainRepository,
            availabilityTemplateRepository,
            availabilityWindowRepository,
            slotRepository,
            passwordService);
  }

  @Test
  @DisplayName("registerCoach should register coach with is_verified=false and default ACC")
  void testRegisterCoachSuccessAcc() {
    when(userRepository.findByEmailIgnoreCase("coach@example.com")).thenReturn(Optional.empty());
    when(passwordService.hashPassword("SecurePass#123")).thenReturn("hashedPassword");

    UUID userId = UUID.randomUUID();
    UserEntity savedUser = new UserEntity();
    savedUser.setUserId(userId);
    savedUser.setEmail("coach@example.com");
    savedUser.setRole(UserRole.COACH);
    when(userRepository.save(any(UserEntity.class))).thenReturn(savedUser);

    UUID coachId = UUID.randomUUID();
    CoachEntity savedCoach = new CoachEntity();
    savedCoach.setCoachId(coachId);
    savedCoach.setUser(savedUser);
    savedCoach.setFirstName("Jane");
    savedCoach.setLastName("Doe");
    savedCoach.setPhotoUrl("https://example.com/photo.jpg");
    savedCoach.setGender(Gender.FEMALE);
    savedCoach.setCountryCode("US");
    savedCoach.setTimezone("America/New_York");
    savedCoach.setBiography("Experienced leadership coach.");
    savedCoach.setIcfAcc(true);
    savedCoach.setIcfPcc(false);
    savedCoach.setIcfMcc(false);
    savedCoach.setIcfActc(false);
    savedCoach.setCredentialDetails("ICF-12345 | Hourly Rate: $150.00 USD");
    savedCoach.setVerified(false);
    savedCoach.setOnboarded(false);
    savedCoach.setCreatedAt(Instant.now());
    when(coachRepository.save(any(CoachEntity.class))).thenReturn(savedCoach);

    DomainEntity domainEntity = new DomainEntity();
    domainEntity.setDomainId(UUID.randomUUID());
    domainEntity.setCode("CAREER");
    domainEntity.setName("Career Development");
    String longDomainName = "VERY_LONG_CUSTOM_COACHING_DOMAIN_SPECIALIZATION_NAME";
    when(domainRepository.findByCodeIgnoreCase("CAREER")).thenReturn(Optional.of(domainEntity));
    when(domainRepository.findByCodeIgnoreCase("UNKNOWN")).thenReturn(Optional.empty());
    when(domainRepository.findByCodeIgnoreCase(longDomainName)).thenReturn(Optional.empty());
    when(domainRepository.save(any(DomainEntity.class)))
        .thenAnswer(
            invocation -> {
              DomainEntity inputDomain = invocation.getArgument(0);
              if ("UNKNOWN".equals(inputDomain.getCode())) {
                return null;
              } else {
                return inputDomain;
              }
            });

    CoachRegistrationCommand command =
        new CoachRegistrationCommand(
            "coach@example.com",
            "SecurePass#123",
            "Jane",
            "Doe",
            "https://example.com/photo.jpg",
            "FEMALE",
            "US",
            "America/New_York",
            "Experienced leadership coach.",
            "ACC",
            true,
            false,
            false,
            false,
            "ICF-12345",
            List.of("CAREER", "UNKNOWN", longDomainName, "   "),
            new BigDecimal("150.00"));

    CoachProfileDetails details = coachService.registerCoach(command);

    assertNotNull(details);
    assertEquals(coachId, details.coachId());
    assertEquals(userId, details.userId());
    assertEquals("coach@example.com", details.email());
    assertFalse(details.isVerified());
    assertEquals("ACC", details.icfLevel());
    assertEquals("https://example.com/photo.jpg", details.photoUrl());
    assertEquals("FEMALE", details.gender());
    assertEquals("US", details.countryCode());
    assertEquals(new BigDecimal("150.00"), details.hourlyRate());
    assertTrue(details.domainCodes().contains("CAREER"));
    assertTrue(details.domainCodes().contains("UNKNOWN"));
  }

  @Test
  @DisplayName("registerCoach should handle PCC, MCC, ACTC levels, invalid gender/country and null details")
  void testRegisterCoachDifferentLevels() {
    when(userRepository.findByEmailIgnoreCase("pcc@example.com")).thenReturn(Optional.empty());
    when(passwordService.hashPassword(anyString())).thenReturn("hashed");

    UserEntity savedUser = new UserEntity();
    savedUser.setUserId(UUID.randomUUID());
    savedUser.setEmail("pcc@example.com");
    savedUser.setRole(UserRole.COACH);
    when(userRepository.save(any(UserEntity.class))).thenReturn(savedUser);

    CoachEntity savedCoach = new CoachEntity();
    savedCoach.setCoachId(UUID.randomUUID());
    savedCoach.setUser(savedUser);
    savedCoach.setFirstName("John");
    savedCoach.setLastName("Smith");
    savedCoach.setTimezone("UTC");
    savedCoach.setIcfAcc(false);
    savedCoach.setIcfPcc(true);
    savedCoach.setIcfMcc(false);
    savedCoach.setIcfActc(false);
    savedCoach.setVerified(false);
    savedCoach.setOnboarded(false);
    savedCoach.setCreatedAt(Instant.now());
    when(coachRepository.save(any(CoachEntity.class))).thenReturn(savedCoach);

    CoachRegistrationCommand commandPcc =
        new CoachRegistrationCommand(
            "pcc@example.com",
            "SecurePass#123",
            "John",
            "Smith",
            "   ",
            "INVALID_GENDER",
            "TOOLONG",
            "UTC",
            null,
            "PCC",
            null,
            null,
            null,
            null,
            null,
            null,
            new BigDecimal("200.00"));

    CoachProfileDetails detailsPcc = coachService.registerCoach(commandPcc);
    assertEquals("PCC", detailsPcc.icfLevel());
    assertNull(detailsPcc.photoUrl());
    assertNull(detailsPcc.gender());
    assertNull(detailsPcc.countryCode());

    // MCC Level
    savedCoach.setIcfPcc(false);
    savedCoach.setIcfMcc(true);
    CoachRegistrationCommand commandMcc =
        new CoachRegistrationCommand(
            "mcc@example.com",
            "SecurePass#123",
            "John",
            "Smith",
            "MCC",
            "ICF-999",
            null,
            "UTC",
            null,
            null);
    when(userRepository.findByEmailIgnoreCase("mcc@example.com")).thenReturn(Optional.empty());
    savedUser.setEmail("mcc@example.com");
    CoachProfileDetails detailsMcc = coachService.registerCoach(commandMcc);
    assertEquals("MCC", detailsMcc.icfLevel());

    // ACTC Level
    savedCoach.setIcfMcc(false);
    savedCoach.setIcfActc(true);
    CoachRegistrationCommand commandActc =
        new CoachRegistrationCommand(
            "actc@example.com",
            "SecurePass#123",
            "John",
            "Smith",
            "ACTC",
            "ICF-ACTC",
            null,
            "UTC",
            null,
            null);
    when(userRepository.findByEmailIgnoreCase("actc@example.com")).thenReturn(Optional.empty());
    savedUser.setEmail("actc@example.com");
    CoachProfileDetails detailsActc = coachService.registerCoach(commandActc);
    assertEquals("ACTC", detailsActc.icfLevel());
  }

  @Test
  @DisplayName("registerCoach should throw on null command, blank fields, invalid bounds, existing email")
  void testRegisterCoachValidationFailures() {
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(null));

    CoachRegistrationCommand blankEmail =
        new CoachRegistrationCommand("  ", "Pass#12345", "A", "B", "ACC", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankEmail));

    CoachRegistrationCommand blankPassword =
        new CoachRegistrationCommand("a@b.com", "   ", "A", "B", "ACC", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankPassword));

    CoachRegistrationCommand blankFirstName =
        new CoachRegistrationCommand("a@b.com", "Pass#12345", "  ", "B", "ACC", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankFirstName));

    CoachRegistrationCommand blankLastName =
        new CoachRegistrationCommand("a@b.com", "Pass#12345", "A", "  ", "ACC", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankLastName));

    CoachRegistrationCommand blankTimezone =
        new CoachRegistrationCommand("a@b.com", "Pass#12345", "A", "B", "ACC", "", null, "  ", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankTimezone));

    CoachRegistrationCommand shortPass =
        new CoachRegistrationCommand("a@b.com", "short", "A", "B", "ACC", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(shortPass));

    CoachRegistrationCommand longPass =
        new CoachRegistrationCommand("a@b.com", "a".repeat(33), "A", "B", "ACC", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(longPass));

    CoachRegistrationCommand invalidIcf =
        new CoachRegistrationCommand("a@b.com", "Pass#12345", "A", "B", "INVALID", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(invalidIcf));

    CoachRegistrationCommand blankIcf =
        new CoachRegistrationCommand("a@b.com", "Pass#12345", "A", "B", "   ", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankIcf));

    CoachRegistrationCommand existingEmail =
        new CoachRegistrationCommand("dup@b.com", "Pass#12345", "A", "B", "ACC", "", null, "UTC", null, null);
    when(userRepository.findByEmailIgnoreCase("dup@b.com"))
        .thenReturn(Optional.of(new UserEntity()));
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(existingEmail));
  }

  @Test
  @DisplayName("updateCoachProfile should update coach profile, credential checkboxes, and domains successfully")
  void testUpdateCoachProfileSuccess() {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setEmail("coach@example.com");

    CoachEntity coachEntity = new CoachEntity();
    coachEntity.setCoachId(coachId);
    coachEntity.setUser(userEntity);
    coachEntity.setFirstName("Old");
    coachEntity.setLastName("Name");
    coachEntity.setTimezone("UTC");
    coachEntity.setIcfAcc(true);
    coachEntity.setIcfPcc(false);
    coachEntity.setIcfMcc(false);
    coachEntity.setIcfActc(false);
    coachEntity.setVerified(false);
    coachEntity.setOnboarded(false);
    coachEntity.setCreatedAt(Instant.now());

    when(coachRepository.findByUser_UserId(userId)).thenReturn(Optional.of(coachEntity));
    when(coachRepository.save(any(CoachEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    CoachDomainEntity oldDomain = new CoachDomainEntity();
    oldDomain.setCoach(coachEntity);
    when(coachDomainRepository.findByCoach_CoachId(coachId)).thenReturn(List.of(oldDomain));

    DomainEntity domainEntity = new DomainEntity();
    domainEntity.setCode("EXECUTIVE");
    when(domainRepository.findByCodeIgnoreCase("EXECUTIVE")).thenReturn(Optional.of(domainEntity));

    CoachUpdateCommand command =
        new CoachUpdateCommand(
            "NewFirst",
            "NewLast",
            "https://photo.example.com",
            "MALE",
            "GB",
            "Europe/London",
            "Updated biography text.",
            null,
            true,
            true,
            false,
            true,
            "Updated ICF details",
            List.of("EXECUTIVE"),
            new BigDecimal("250.00"));

    CoachProfileDetails updated = coachService.updateCoachProfile(userId, command);

    assertNotNull(updated);
    assertEquals("NewFirst", updated.firstName());
    assertEquals("NewLast", updated.lastName());
    assertEquals("Europe/London", updated.timezone());
    assertEquals("Updated biography text.", updated.biography());
    assertTrue(updated.icfAcc());
    assertTrue(updated.icfPcc());
    assertFalse(updated.icfMcc());
    assertTrue(updated.icfActc());
    assertEquals("https://photo.example.com", updated.photoUrl());
    assertEquals("MALE", updated.gender());
    assertEquals("GB", updated.countryCode());
    assertEquals(new BigDecimal("250.00"), updated.hourlyRate());
    verify(coachDomainRepository).deleteAll(any());
  }

  @Test
  @DisplayName("updateCoachProfile should fallback to single level string when booleans are empty")
  void testUpdateCoachProfileFallbackLevel() {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setEmail("coach@example.com");

    CoachEntity coachEntity = new CoachEntity();
    coachEntity.setCoachId(coachId);
    coachEntity.setUser(userEntity);
    coachEntity.setFirstName("Old");
    coachEntity.setLastName("Name");
    coachEntity.setTimezone("UTC");
    coachEntity.setIcfAcc(false);
    coachEntity.setIcfPcc(false);
    coachEntity.setIcfMcc(false);
    coachEntity.setIcfActc(false);
    coachEntity.setVerified(false);
    coachEntity.setOnboarded(false);
    coachEntity.setCreatedAt(Instant.now());

    when(coachRepository.findByUser_UserId(userId)).thenReturn(Optional.of(coachEntity));
    when(coachRepository.save(any(CoachEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    CoachUpdateCommand commandAcc =
        new CoachUpdateCommand(
            "NewFirst", "NewLast", null, null, null, "UTC", null, "ACC", null, null, null, null, null, null, null);
    CoachProfileDetails updatedAcc = coachService.updateCoachProfile(userId, commandAcc);
    assertTrue(updatedAcc.icfAcc());

    CoachUpdateCommand commandPcc =
        new CoachUpdateCommand(
            "NewFirst", "NewLast", null, null, null, "UTC", null, "PCC", null, null, null, null, null, null, null);
    CoachProfileDetails updatedPcc = coachService.updateCoachProfile(userId, commandPcc);
    assertTrue(updatedPcc.icfPcc());

    CoachUpdateCommand commandMcc =
        new CoachUpdateCommand(
            "NewFirst", "NewLast", null, null, null, "UTC", null, "MCC", null, null, null, null, null, null, null);
    CoachProfileDetails updatedMcc = coachService.updateCoachProfile(userId, commandMcc);
    assertTrue(updatedMcc.icfMcc());

    CoachUpdateCommand commandActc =
        new CoachUpdateCommand(
            "NewFirst", "NewLast", null, null, null, "UTC", null, "ACTC", null, null, null, null, null, null, null);
    CoachProfileDetails updatedActc = coachService.updateCoachProfile(userId, commandActc);
    assertTrue(updatedActc.icfActc());
  }

  @Test
  @DisplayName("updateCoachProfile should validate input parameters and throw appropriate exceptions")
  void testUpdateCoachProfileValidationFailures() {
    UUID userId = UUID.randomUUID();

    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(null, null));
    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(userId, null));

    CoachUpdateCommand blankFirst =
        new CoachUpdateCommand(" ", "L", null, null, null, "UTC", null, "ACC", null, null, null, null, null, null, null);
    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(userId, blankFirst));

    CoachUpdateCommand blankLast =
        new CoachUpdateCommand("F", " ", null, null, null, "UTC", null, "ACC", null, null, null, null, null, null, null);
    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(userId, blankLast));

    CoachUpdateCommand blankTz =
        new CoachUpdateCommand("F", "L", null, null, null, " ", null, "ACC", null, null, null, null, null, null, null);
    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(userId, blankTz));

    CoachUpdateCommand validCmd =
        new CoachUpdateCommand("F", "L", null, null, null, "UTC", null, "ACC", null, null, null, null, null, null, null);
    when(coachRepository.findByUser_UserId(userId)).thenReturn(Optional.empty());
    assertThrows(
        IllegalStateException.class, () -> coachService.updateCoachProfile(userId, validCmd));

    CoachEntity coachEntity = new CoachEntity();
    when(coachRepository.findByUser_UserId(userId)).thenReturn(Optional.of(coachEntity));

    CoachUpdateCommand noIcf =
        new CoachUpdateCommand("F", "L", null, null, null, "UTC", null, "INVALID", false, false, false, false, null, null, null);
    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(userId, noIcf));

    CoachUpdateCommand blankIcf =
        new CoachUpdateCommand("F", "L", null, null, null, "UTC", null, "   ", false, false, false, false, null, null, null);
    assertThrows(
        IllegalArgumentException.class, () -> coachService.updateCoachProfile(userId, blankIcf));
  }

  @Test
  @DisplayName("getCoachProfileByUserId should handle different hourly rate formats and invalid rate string")
  void testHourlyRateParsingVariants() {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setEmail("rate@example.com");

    CoachEntity coachEntity = new CoachEntity();
    coachEntity.setCoachId(coachId);
    coachEntity.setUser(userEntity);
    coachEntity.setFirstName("Jane");
    coachEntity.setLastName("Doe");
    coachEntity.setTimezone("UTC");
    coachEntity.setIcfAcc(true);
    coachEntity.setIcfPcc(false);
    coachEntity.setIcfMcc(false);
    coachEntity.setIcfActc(false);
    coachEntity.setVerified(true);
    coachEntity.setOnboarded(true);
    coachEntity.setCreatedAt(Instant.now());

    // Without space after rate
    coachEntity.setCredentialDetails("Hourly Rate: $175.50");
    when(coachRepository.findByUser_UserId(userId)).thenReturn(Optional.of(coachEntity));
    when(coachDomainRepository.findByCoach_CoachId(coachId)).thenReturn(List.of());

    CoachProfileDetails details = coachService.getCoachProfileByUserId(userId);
    assertEquals(new BigDecimal("175.50"), details.hourlyRate());

    // With non-numeric rate
    coachEntity.setCredentialDetails("Hourly Rate: $NotANumber");
    CoachProfileDetails detailsInvalid = coachService.getCoachProfileByUserId(userId);
    assertNull(detailsInvalid.hourlyRate());

    // Without hourly rate marker
    coachEntity.setCredentialDetails("Plain credential details");
    CoachProfileDetails detailsPlain = coachService.getCoachProfileByUserId(userId);
    assertNull(detailsPlain.hourlyRate());

    // Blank details
    coachEntity.setCredentialDetails("   ");
    CoachProfileDetails detailsBlank = coachService.getCoachProfileByUserId(userId);
    assertNull(detailsBlank.hourlyRate());
  }

  @Test
  @DisplayName("getCoachProfileByUserId should return details and domain codes")
  void testGetCoachProfileSuccess() {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setEmail("coach@example.com");

    CoachEntity coachEntity = new CoachEntity();
    coachEntity.setCoachId(coachId);
    coachEntity.setUser(userEntity);
    coachEntity.setFirstName("Jane");
    coachEntity.setLastName("Doe");
    coachEntity.setTimezone("America/New_York");
    coachEntity.setIcfAcc(true);
    coachEntity.setIcfPcc(false);
    coachEntity.setIcfMcc(false);
    coachEntity.setIcfActc(false);
    coachEntity.setVerified(true);
    coachEntity.setOnboarded(true);
    coachEntity.setCreatedAt(Instant.now());

    DomainEntity domainEntity = new DomainEntity();
    domainEntity.setCode("LEADERSHIP");
    CoachDomainEntity coachDomainEntity = new CoachDomainEntity();
    coachDomainEntity.setCoach(coachEntity);
    coachDomainEntity.setDomain(domainEntity);

    when(coachRepository.findByUser_UserId(userId)).thenReturn(Optional.of(coachEntity));
    when(coachDomainRepository.findByCoach_CoachId(coachId)).thenReturn(List.of(coachDomainEntity));

    CoachProfileDetails details = coachService.getCoachProfileByUserId(userId);

    assertNotNull(details);
    assertTrue(details.isVerified());
    assertEquals("ACC", details.icfLevel());
    assertEquals(List.of("LEADERSHIP"), details.domainCodes());
  }

  @Test
  @DisplayName("getCoachProfileByUserId should throw when user id is null or coach not found")
  void testGetCoachProfileFailures() {
    assertThrows(IllegalArgumentException.class, () -> coachService.getCoachProfileByUserId(null));

    UUID unknownUserId = UUID.randomUUID();
    when(coachRepository.findByUser_UserId(unknownUserId)).thenReturn(Optional.empty());
    assertThrows(
        IllegalStateException.class, () -> coachService.getCoachProfileByUserId(unknownUserId));
  }

  @Test
  @DisplayName("generateUpcomingAvailabilitiesForAllCoaches should create default template and windows when none exist")
  void testGenerateUpcomingAvailabilitiesWithDefaultTemplateAndWindows() {
    final UUID coachOneId = UUID.randomUUID();
    final UUID coachTwoId = UUID.randomUUID();

    CoachEntity coachOne = new CoachEntity();
    coachOne.setCoachId(coachOneId);
    coachOne.setTimezone("America/New_York");

    CoachEntity coachTwo = new CoachEntity();
    coachTwo.setCoachId(coachTwoId);
    coachTwo.setTimezone("   ");

    when(coachRepository.findAll()).thenReturn(List.of(coachOne, coachTwo));
    when(availabilityTemplateRepository.findByCoach_CoachId(coachOneId))
        .thenReturn(Optional.empty());
    when(availabilityTemplateRepository.findByCoach_CoachId(coachTwoId))
        .thenReturn(Optional.empty());

    AtomicInteger templateSaveCounter = new AtomicInteger();
    when(availabilityTemplateRepository.save(any(AvailabilityTemplateEntity.class)))
        .thenAnswer(
            invocation -> {
              AvailabilityTemplateEntity inputTemplate = invocation.getArgument(0);
              inputTemplate.setAvailabilityTemplateId(UUID.randomUUID());
              if (templateSaveCounter.getAndIncrement() == 0) {
                return inputTemplate;
              } else {
                return null;
              }
            });

    when(availabilityWindowRepository
            .findByAvailabilityTemplate_AvailabilityTemplateIdOrderByDayOfWeekAscStartTimeAsc(any()))
        .thenReturn(List.of());

    AtomicInteger windowSaveCounter = new AtomicInteger();
    when(availabilityWindowRepository.save(any(AvailabilityWindowEntity.class)))
        .thenAnswer(
            invocation -> {
              AvailabilityWindowEntity inputWindow = invocation.getArgument(0);
              if (windowSaveCounter.getAndIncrement() < 2) {
                return inputWindow;
              } else {
                return null;
              }
            });

    when(slotRepository
            .findByAvailabilityTemplate_AvailabilityTemplateIdAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(
                any(), any(Instant.class), any(Instant.class)))
        .thenReturn(List.of());

    AtomicInteger slotSaveCounter = new AtomicInteger();
    when(slotRepository.save(any(SlotEntity.class)))
        .thenAnswer(
            invocation -> {
              SlotEntity inputSlot = invocation.getArgument(0);
              if (slotSaveCounter.getAndIncrement() % 2 == 0) {
                return inputSlot;
              } else {
                return null;
              }
            });

    int createdSlots = coachService.generateUpcomingAvailabilitiesForAllCoaches();

    // 2 coaches * 30 days * 6 one-hour slots per day = 360 slots
    assertEquals(360, createdSlots);
  }

  @Test
  @DisplayName("generateUpcomingAvailabilitiesForAllCoaches should handle existing templates, 30-min durations, and overlaps")
  void testGenerateUpcomingAvailabilitiesWithExistingTemplatesAndOverlaps() {
    final UUID coachOneId = UUID.randomUUID();
    final UUID coachTwoId = UUID.randomUUID();
    final UUID coachThreeId = UUID.randomUUID();
    final UUID templateOneId = UUID.randomUUID();
    final UUID templateTwoId = UUID.randomUUID();
    final UUID templateThreeId = UUID.randomUUID();

    CoachEntity coachOne = new CoachEntity();
    coachOne.setCoachId(coachOneId);
    coachOne.setTimezone("Invalid/Timezone_String");

    CoachEntity coachTwo = new CoachEntity();
    coachTwo.setCoachId(coachTwoId);
    coachTwo.setTimezone(null);

    CoachEntity coachThree = new CoachEntity();
    coachThree.setCoachId(coachThreeId);
    coachThree.setTimezone("UTC");

    when(coachRepository.findAll()).thenReturn(List.of(coachOne, coachTwo, coachThree));

    AvailabilityTemplateEntity templateOne = new AvailabilityTemplateEntity();
    templateOne.setAvailabilityTemplateId(templateOneId);
    templateOne.setCoach(coachOne);
    templateOne.setSlotDurationMinutes((short) 30);
    templateOne.setActive(true);
    when(availabilityTemplateRepository.findByCoach_CoachId(coachOneId))
        .thenReturn(Optional.of(templateOne));

    AvailabilityTemplateEntity templateTwo = new AvailabilityTemplateEntity();
    templateTwo.setAvailabilityTemplateId(templateTwoId);
    templateTwo.setCoach(coachTwo);
    templateTwo.setSlotDurationMinutes(null);
    templateTwo.setActive(false);
    when(availabilityTemplateRepository.findByCoach_CoachId(coachTwoId))
        .thenReturn(Optional.of(templateTwo));

    AvailabilityTemplateEntity templateThree = new AvailabilityTemplateEntity();
    templateThree.setAvailabilityTemplateId(templateThreeId);
    templateThree.setCoach(coachThree);
    templateThree.setSlotDurationMinutes((short) 60);
    templateThree.setActive(false);
    when(availabilityTemplateRepository.findByCoach_CoachId(coachThreeId))
        .thenReturn(Optional.of(templateThree));

    AtomicInteger updateTemplateCounter = new AtomicInteger();
    when(availabilityTemplateRepository.save(any(AvailabilityTemplateEntity.class)))
        .thenAnswer(
            invocation -> {
              if (updateTemplateCounter.getAndIncrement() == 0) {
                return invocation.getArgument(0);
              } else {
                return null;
              }
            });

    LocalDate todayUtc = LocalDate.now(ZoneOffset.UTC);
    short todayDayOfWeek = (short) todayUtc.getDayOfWeek().getValue();

    AvailabilityWindowEntity validWindow = new AvailabilityWindowEntity();
    validWindow.setDayOfWeek(todayDayOfWeek);
    validWindow.setStartTime(LocalTime.of(9, 0));
    validWindow.setEndTime(LocalTime.of(10, 0));

    AvailabilityWindowEntity nullDayWindow = new AvailabilityWindowEntity();
    nullDayWindow.setDayOfWeek(null);
    nullDayWindow.setStartTime(LocalTime.of(11, 0));
    nullDayWindow.setEndTime(LocalTime.of(12, 0));

    when(availabilityWindowRepository
            .findByAvailabilityTemplate_AvailabilityTemplateIdOrderByDayOfWeekAscStartTimeAsc(
                any(UUID.class)))
        .thenReturn(List.of(validWindow, nullDayWindow));

    Instant existingTodayStart =
        ZonedDateTime.of(todayUtc, LocalTime.of(9, 0), ZoneOffset.UTC).toInstant();
    SlotEntity overlappingSlot = new SlotEntity();
    overlappingSlot.setSlotId(UUID.randomUUID());
    overlappingSlot.setStartAt(existingTodayStart);
    overlappingSlot.setEndAt(existingTodayStart.plus(Duration.ofMinutes(30)));
    overlappingSlot.setFreePledge(true);

    SlotEntity laterSlotSameDay = new SlotEntity();
    laterSlotSameDay.setSlotId(UUID.randomUUID());
    laterSlotSameDay.setStartAt(existingTodayStart.plus(Duration.ofHours(5)));
    laterSlotSameDay.setEndAt(existingTodayStart.plus(Duration.ofHours(6)));
    laterSlotSameDay.setFreePledge(false);

    SlotEntity differentMonthSlot = new SlotEntity();
    differentMonthSlot.setSlotId(UUID.randomUUID());
    differentMonthSlot.setStartAt(existingTodayStart.minus(Duration.ofDays(40)));
    differentMonthSlot.setEndAt(
        existingTodayStart.minus(Duration.ofDays(40)).plus(Duration.ofMinutes(60)));
    differentMonthSlot.setFreePledge(true);

    when(slotRepository
            .findByAvailabilityTemplate_AvailabilityTemplateIdAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(
                any(UUID.class), any(Instant.class), any(Instant.class)))
        .thenReturn(List.of(overlappingSlot, laterSlotSameDay, differentMonthSlot));

    when(slotRepository.save(any(SlotEntity.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));

    int createdSlots = coachService.generateUpcomingAvailabilitiesForAllCoaches();

    assertTrue(createdSlots > 0);
  }

  @Test
  @DisplayName("getCoachAvailabilities should return unbooked slots and validate parameters")
  void testGetCoachAvailabilities() {
    UUID coachId = UUID.randomUUID();
    CoachEntity coachEntity = new CoachEntity();
    coachEntity.setCoachId(coachId);

    // Null coachId
    assertThrows(
        IllegalArgumentException.class,
        () -> coachService.getCoachAvailabilities(null, null, null));

    // Coach not found
    when(coachRepository.findById(coachId)).thenReturn(Optional.empty());
    assertThrows(
        IllegalStateException.class,
        () -> coachService.getCoachAvailabilities(coachId, null, null));

    when(coachRepository.findById(coachId)).thenReturn(Optional.of(coachEntity));

    // Invalid date range (to < from)
    Instant from = Instant.now().plus(Duration.ofDays(2));
    Instant toBeforeFrom = from.minus(Duration.ofHours(1));
    assertThrows(
        IllegalArgumentException.class,
        () -> coachService.getCoachAvailabilities(coachId, from, toBeforeFrom));

    // Valid query with explicit from & to
    SlotEntity slotEntity = new SlotEntity();
    slotEntity.setSlotId(UUID.randomUUID());
    slotEntity.setStartAt(from.plus(Duration.ofHours(1)));
    slotEntity.setEndAt(from.plus(Duration.ofHours(2)));
    slotEntity.setFreePledge(true);

    Instant to = from.plus(Duration.ofDays(7));
    when(slotRepository.findAvailableSlotsByCoachInWindow(coachId, from, to))
        .thenReturn(List.of(slotEntity));

    List<CoachAvailabilitySlotDetails> explicitRangeResult =
        coachService.getCoachAvailabilities(coachId, from, to);
    assertEquals(1, explicitRangeResult.size());
    assertEquals(60, explicitRangeResult.get(0).durationMinutes());
    assertTrue(explicitRangeResult.get(0).isFreePledge());

    // Valid query with null from & to (uses default window)
    when(slotRepository.findAvailableSlotsByCoachInWindow(
            any(UUID.class), any(Instant.class), any(Instant.class)))
        .thenReturn(List.of(slotEntity));
    List<CoachAvailabilitySlotDetails> openRangeResult =
        coachService.getCoachAvailabilities(coachId, null, null);
    assertEquals(1, openRangeResult.size());
  }
}
