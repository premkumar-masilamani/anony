package com.anony.domain.coach;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
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
    savedCoach.setTimezone("America/New_York");
    savedCoach.setBiography("Experienced leadership coach.");
    savedCoach.setIcfAcc(true);
    savedCoach.setIcfPcc(false);
    savedCoach.setIcfMcc(false);
    savedCoach.setIcfActc(false);
    savedCoach.setCredentialDetails("ICF-12345 | Hourly Rate: $150.00");
    savedCoach.setVerified(false);
    savedCoach.setOnboarded(false);
    savedCoach.setCreatedAt(Instant.now());
    when(coachRepository.save(any(CoachEntity.class))).thenReturn(savedCoach);

    DomainEntity domainEntity = new DomainEntity();
    domainEntity.setDomainId(UUID.randomUUID());
    domainEntity.setCode("CAREER");
    domainEntity.setName("Career Development");
    when(domainRepository.findByCodeIgnoreCase("CAREER")).thenReturn(Optional.of(domainEntity));
    when(domainRepository.findByCodeIgnoreCase("UNKNOWN")).thenReturn(Optional.empty());

    CoachRegistrationCommand command =
        new CoachRegistrationCommand(
            "coach@example.com",
            "SecurePass#123",
            "Jane",
            "Doe",
            "ACC",
            "ICF-12345",
            List.of("CAREER", "UNKNOWN", "   "),
            "America/New_York",
            "Experienced leadership coach.",
            new BigDecimal("150.00"));

    CoachProfileDetails details = coachService.registerCoach(command);

    assertNotNull(details);
    assertEquals(coachId, details.coachId());
    assertEquals(userId, details.userId());
    assertEquals("coach@example.com", details.email());
    assertFalse(details.isVerified());
    assertEquals("ACC", details.icfLevel());
    assertTrue(details.domainCodes().contains("CAREER"));
    assertTrue(details.domainCodes().contains("UNKNOWN"));
  }

  @Test
  @DisplayName("registerCoach should handle PCC, MCC, ACTC levels and null credential details")
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
            "PCC",
            null,
            null,
            "UTC",
            null,
            new BigDecimal("200.00"));

    CoachProfileDetails detailsPcc = coachService.registerCoach(commandPcc);
    assertEquals("PCC", detailsPcc.icfLevel());

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

    CoachRegistrationCommand blankIcfLevel =
        new CoachRegistrationCommand("a@b.com", "Pass#12345", "A", "B", "  ", "", null, "UTC", null, null);
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(blankIcfLevel));

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

    CoachRegistrationCommand existingEmail =
        new CoachRegistrationCommand("dup@b.com", "Pass#12345", "A", "B", "ACC", "", null, "UTC", null, null);
    when(userRepository.findByEmailIgnoreCase("dup@b.com"))
        .thenReturn(Optional.of(new UserEntity()));
    assertThrows(IllegalArgumentException.class, () -> coachService.registerCoach(existingEmail));
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
}
