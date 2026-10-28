package com.anony.domain.session;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.anony.persistence.entities.AvailabilityTemplateEntity;
import com.anony.persistence.entities.ClientEntity;
import com.anony.persistence.entities.CoachEntity;
import com.anony.persistence.entities.DomainEntity;
import com.anony.persistence.entities.SessionEntity;
import com.anony.persistence.entities.SlotEntity;
import com.anony.persistence.enums.SessionStatus;
import com.anony.persistence.repositories.ClientRepository;
import com.anony.persistence.repositories.DomainRepository;
import com.anony.persistence.repositories.SessionRepository;
import com.anony.persistence.repositories.SlotRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class DefaultSessionServiceTest {

  @Mock
  private ClientRepository clientRepository;

  @Mock
  private SlotRepository slotRepository;

  @Mock
  private SessionRepository sessionRepository;

  @Mock
  private DomainRepository domainRepository;

  private DefaultSessionService sessionService;

  @BeforeEach
  void setUp() {
    sessionService =
        new DefaultSessionService(
            clientRepository, slotRepository, sessionRepository, domainRepository);
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalArgumentException when command is null")
  void testScheduleBlindMatchNullCommand() {
    assertThrows(
        IllegalArgumentException.class,
        () -> sessionService.scheduleBlindMatch(null));
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalArgumentException when both struggle prompt and domain code are blank for free booking")
  void testScheduleBlindMatchBlankPromptAndDomain() {
    UUID userId = UUID.randomUUID();
    BlindMatchCommand command =
        new BlindMatchCommand(
            userId, BookingType.FREE, null, null, "   ", "   ", TimeWindow.EVENING, LocalDate.now());

    assertThrows(
        IllegalArgumentException.class,
        () -> sessionService.scheduleBlindMatch(command));
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalStateException when client is missing")
  void testScheduleBlindMatchClientNotFound() {
    UUID userId = UUID.randomUUID();
    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            BookingType.FREE,
            null,
            null,
            null,
            "Need leadership support",
            TimeWindow.MORNING,
            LocalDate.now());

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.empty());

    assertThrows(
        IllegalStateException.class,
        () -> sessionService.scheduleBlindMatch(command));
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw QuotaExceededException when lifetime cap (6) is reached")
  void testScheduleBlindMatchLifetimeCapReached() {
    UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(6);

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            BookingType.FREE,
            null,
            null,
            null,
            "Need support",
            TimeWindow.AFTERNOON,
            LocalDate.now());

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));

    QuotaExceededException quotaException =
        assertThrows(
            QuotaExceededException.class,
            () -> sessionService.scheduleBlindMatch(command));

    assertEquals("LIFETIME_CAP_REACHED", quotaException.getReason());
    assertEquals(0, quotaException.getDaysRemaining());
    assertEquals(6, quotaException.getFreeSessionsUsed());
    assertEquals(6, quotaException.getMaxFreeSessions());
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw QuotaExceededException when 14-day cooldown is active")
  void testScheduleBlindMatchCooldownActive() {
    UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(2);
    client.setLastFreeSessionAt(Instant.now().minus(5, ChronoUnit.DAYS));

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            BookingType.FREE,
            null,
            null,
            null,
            "Need support",
            TimeWindow.EVENING,
            LocalDate.now());

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));

    QuotaExceededException quotaException =
        assertThrows(
            QuotaExceededException.class,
            () -> sessionService.scheduleBlindMatch(command));

    assertEquals("COOLDOWN_ACTIVE", quotaException.getReason());
    assertEquals(9, quotaException.getDaysRemaining());
    assertEquals(2, quotaException.getFreeSessionsUsed());
  }

  @Test
  @DisplayName("scheduleBlindMatch should match slot in requested window and confirm free session")
  void testScheduleBlindMatchSuccessInWindow() {
    final UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(0);
    client.setLastFreeSessionAt(null);

    CoachEntity coach = new CoachEntity();
    coach.setCoachId(UUID.randomUUID());
    coach.setFirstName("AuraGuide");
    coach.setIcfPcc(true);

    AvailabilityTemplateEntity template = new AvailabilityTemplateEntity();
    template.setCoach(coach);
    template.setActive(true);

    SlotEntity slot = new SlotEntity();
    slot.setSlotId(UUID.randomUUID());
    slot.setAvailabilityTemplate(template);
    slot.setStartAt(Instant.now().plus(1, ChronoUnit.DAYS));
    slot.setEndAt(Instant.now().plus(1, ChronoUnit.DAYS).plus(1, ChronoUnit.HOURS));

    SessionEntity savedSession = new SessionEntity();
    savedSession.setSessionId(UUID.randomUUID());
    savedSession.setSlot(slot);
    savedSession.setClient(client);
    savedSession.setTopic("Overwhelmed with executive burnout");
    savedSession.setStatus(SessionStatus.CONFIRMED);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));
    when(slotRepository.findAvailableSlotsInWindow(any(Instant.class), any(Instant.class)))
        .thenReturn(List.of(slot));
    when(sessionRepository.save(any(SessionEntity.class))).thenReturn(savedSession);
    when(clientRepository.save(any(ClientEntity.class))).thenReturn(client);

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            BookingType.FREE,
            null,
            null,
            null,
            "Overwhelmed with executive burnout",
            TimeWindow.EVENING,
            LocalDate.now().plusDays(1));

    BlindMatchResult result = sessionService.scheduleBlindMatch(command);

    assertNotNull(result);
    assertEquals(savedSession.getSessionId(), result.sessionId());
    assertEquals(slot.getSlotId(), result.slotId());
    assertEquals(coach.getCoachId(), result.coachId());
    assertEquals("Coach AuraGuide", result.coachAlias());
    assertEquals("PCC", result.coachIcfLevel());
    assertNull(result.domainCode());
    assertEquals("Overwhelmed with executive burnout", result.topic());
    assertEquals(slot.getStartAt(), result.scheduledTime());
    assertEquals(slot.getEndAt(), result.endTime());
    assertEquals(BookingType.FREE, result.bookingType());
    assertEquals("CONFIRMED", result.status());
    assertFalse(result.awaitingCheckout());
    assertTrue(result.isProBono());
    assertEquals(1, result.freeSessionsUsed());
    assertEquals(6, result.maxFreeSessions());
    assertNotNull(result.nextFreeSessionAvailableAt());

    verify(clientRepository).save(client);
    verify(sessionRepository).save(any(SessionEntity.class));
  }

  @Test
  @DisplayName("scheduleBlindMatch should match free slot by domain code and default topic when struggle prompt is blank")
  void testScheduleBlindMatchWithDomainFilter() {
    final UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(0);

    DomainEntity burnoutDomain = new DomainEntity();
    burnoutDomain.setDomainId(UUID.randomUUID());
    burnoutDomain.setCode("BURNOUT");
    burnoutDomain.setName("Burnout & Stress");

    CoachEntity coach = new CoachEntity();
    coach.setCoachId(UUID.randomUUID());
    coach.setFirstName("Maya");
    coach.setIcfPcc(true);

    AvailabilityTemplateEntity template = new AvailabilityTemplateEntity();
    template.setCoach(coach);
    template.setActive(true);

    SlotEntity domainSlot = new SlotEntity();
    domainSlot.setSlotId(UUID.randomUUID());
    domainSlot.setAvailabilityTemplate(template);
    domainSlot.setStartAt(Instant.now().plus(1, ChronoUnit.DAYS));
    domainSlot.setEndAt(Instant.now().plus(1, ChronoUnit.DAYS).plus(1, ChronoUnit.HOURS));

    SessionEntity savedSession = new SessionEntity();
    savedSession.setSessionId(UUID.randomUUID());
    savedSession.setSlot(domainSlot);
    savedSession.setClient(client);
    savedSession.setDomain(burnoutDomain);
    savedSession.setTopic("Burnout & Stress");
    savedSession.setStatus(SessionStatus.CONFIRMED);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));
    when(domainRepository.findByCodeIgnoreCase("BURNOUT")).thenReturn(Optional.of(burnoutDomain));
    when(slotRepository.findAvailableFreeSlotsByDomainInWindow(
            eq("BURNOUT"), any(Instant.class), any(Instant.class)))
        .thenReturn(List.of(domainSlot));
    when(sessionRepository.save(any(SessionEntity.class))).thenReturn(savedSession);

    BlindMatchCommand domainOnlyCommand =
        new BlindMatchCommand(
            userId, BookingType.FREE, null, null, " burnout ", null, TimeWindow.MORNING, LocalDate.now());

    BlindMatchResult result = sessionService.scheduleBlindMatch(domainOnlyCommand);
    assertEquals("BURNOUT", result.domainCode());
    assertEquals("Burnout & Stress", result.topic());

    // When domain slots in primary window are empty, falls back to general free slots in window
    client.setFreeSessionsCount(0);
    client.setLastFreeSessionAt(null);
    when(slotRepository.findAvailableFreeSlotsByDomainInWindow(
            eq("BURNOUT"), any(Instant.class), any(Instant.class)))
        .thenReturn(Collections.emptyList());
    when(slotRepository.findAvailableSlotsInWindow(any(Instant.class), any(Instant.class)))
        .thenReturn(List.of(domainSlot));

    BlindMatchResult fallbackResult = sessionService.scheduleBlindMatch(domainOnlyCommand);
    assertEquals("BURNOUT", fallbackResult.domainCode());
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalArgumentException when domain code is unknown")
  void testScheduleBlindMatchUnknownDomainCode() {
    UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(0);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));
    when(domainRepository.findByCodeIgnoreCase("INVALID_DOMAIN")).thenReturn(Optional.empty());

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            BookingType.FREE,
            null,
            null,
            "INVALID_DOMAIN",
            "Need help",
            TimeWindow.ANYTIME,
            LocalDate.now());

    assertThrows(
        IllegalArgumentException.class,
        () -> sessionService.scheduleBlindMatch(command));
  }

  @Test
  @DisplayName("scheduleBlindMatch should fall back to general slot when exact window is empty")
  void testScheduleBlindMatchSuccessWithFallbackSlot() {
    final UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(1);
    client.setLastFreeSessionAt(Instant.now().minus(15, ChronoUnit.DAYS));

    CoachEntity coach = new CoachEntity();
    coach.setCoachId(UUID.randomUUID());
    coach.setFirstName("Zephyr");
    coach.setIcfMcc(true);

    AvailabilityTemplateEntity template = new AvailabilityTemplateEntity();
    template.setCoach(coach);

    SlotEntity fallbackSlot = new SlotEntity();
    fallbackSlot.setSlotId(UUID.randomUUID());
    fallbackSlot.setAvailabilityTemplate(template);
    fallbackSlot.setStartAt(Instant.now().plus(2, ChronoUnit.DAYS));

    SessionEntity savedSession = new SessionEntity();
    savedSession.setSessionId(UUID.randomUUID());
    savedSession.setSlot(fallbackSlot);
    savedSession.setClient(client);
    savedSession.setTopic("Career transition");
    savedSession.setStatus(SessionStatus.CONFIRMED);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));
    when(slotRepository.findAvailableSlotsInWindow(any(Instant.class), any(Instant.class)))
        .thenReturn(Collections.emptyList())
        .thenReturn(List.of(fallbackSlot));
    when(sessionRepository.save(any(SessionEntity.class))).thenReturn(savedSession);
    when(clientRepository.save(any(ClientEntity.class))).thenReturn(client);

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            null,
            null,
            null,
            null,
            "Career transition",
            TimeWindow.MORNING,
            LocalDate.now());

    BlindMatchResult result = sessionService.scheduleBlindMatch(command);

    assertNotNull(result);
    assertEquals("Coach Zephyr", result.coachAlias());
    assertEquals("MCC", result.coachIcfLevel());
    assertEquals(2, result.freeSessionsUsed());
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw NoAvailableSlotsException when no slots exist anywhere")
  void testScheduleBlindMatchNoSlotsAvailable() {
    UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(0);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));
    when(slotRepository.findAvailableSlotsInWindow(any(Instant.class), any(Instant.class)))
        .thenReturn(Collections.emptyList());

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId,
            BookingType.FREE,
            null,
            null,
            null,
            "Need urgent support",
            TimeWindow.ANYTIME,
            LocalDate.now());

    assertThrows(
        NoAvailableSlotsException.class,
        () -> sessionService.scheduleBlindMatch(command));
  }

  @Test
  @DisplayName("scheduleBlindMatch should resolve different coach ICF credential levels correctly")
  void testCoachIcfLevels() {
    UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setFreeSessionsCount(0);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));

    // Test ACC
    CoachEntity coachAcc = new CoachEntity();
    coachAcc.setIcfAcc(true);
    AvailabilityTemplateEntity template = new AvailabilityTemplateEntity();
    template.setCoach(coachAcc);
    SlotEntity slot = new SlotEntity();
    slot.setAvailabilityTemplate(template);
    slot.setStartAt(Instant.now());

    SessionEntity session = new SessionEntity();
    session.setStatus(SessionStatus.CONFIRMED);

    when(slotRepository.findAvailableSlotsInWindow(any(), any())).thenReturn(List.of(slot));
    when(sessionRepository.save(any())).thenReturn(session);

    BlindMatchCommand command =
        new BlindMatchCommand(
            userId, BookingType.FREE, null, null, null, "Struggle", TimeWindow.AFTERNOON, null);

    BlindMatchResult result = sessionService.scheduleBlindMatch(command);
    assertEquals("ACC", result.coachIcfLevel());
    assertEquals("SereneGuide", result.coachAlias());

    // Test ACTC + null freeSessionsCount + null preferredTimeWindow
    CoachEntity coachActc = new CoachEntity();
    coachActc.setIcfActc(true);
    template.setCoach(coachActc);
    client.setFreeSessionsCount(null);
    client.setLastFreeSessionAt(null);
    BlindMatchResult resultActc =
        sessionService.scheduleBlindMatch(
            new BlindMatchCommand(
                userId, BookingType.FREE, null, null, null, "Struggle", null, null));
    assertEquals("ACTC", resultActc.coachIcfLevel());

    // Test CERTIFIED (no ICF flags true)
    CoachEntity coachNone = new CoachEntity();
    template.setCoach(coachNone);
    client.setFreeSessionsCount(0);
    client.setLastFreeSessionAt(null);
    BlindMatchResult resultNone = sessionService.scheduleBlindMatch(command);
    assertEquals("CERTIFIED", resultNone.coachIcfLevel());

    // Test null coachEntity
    template.setCoach(null);
    client.setFreeSessionsCount(0);
    client.setLastFreeSessionAt(null);
    BlindMatchResult resultNullCoach = sessionService.scheduleBlindMatch(command);
    assertEquals("CERTIFIED", resultNullCoach.coachIcfLevel());
    assertEquals("SereneGuide", resultNullCoach.coachAlias());
  }

  @Test
  @DisplayName("scheduleBlindMatch should atomically lock slot and book paid session without consuming free quota")
  void testSchedulePaidBookingSuccess() {
    final UUID userId = UUID.randomUUID();
    final UUID coachId = UUID.randomUUID();
    final UUID slotId = UUID.randomUUID();

    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(6);
    Instant lastFreeAt = Instant.now().minus(1, ChronoUnit.DAYS);
    client.setLastFreeSessionAt(lastFreeAt);

    CoachEntity coach = new CoachEntity();
    coach.setCoachId(coachId);
    coach.setFirstName("Daniel");
    coach.setIcfMcc(true);

    AvailabilityTemplateEntity template = new AvailabilityTemplateEntity();
    template.setCoach(coach);
    template.setActive(true);

    SlotEntity slot = new SlotEntity();
    slot.setSlotId(slotId);
    slot.setAvailabilityTemplate(template);
    slot.setStartAt(Instant.now().plus(2, ChronoUnit.DAYS));
    slot.setEndAt(Instant.now().plus(2, ChronoUnit.DAYS).plus(1, ChronoUnit.HOURS));

    DomainEntity leadershipDomain = new DomainEntity();
    leadershipDomain.setDomainId(UUID.randomUUID());
    leadershipDomain.setCode("LEADERSHIP");
    leadershipDomain.setName("Leadership & Executive");

    SessionEntity savedSession = new SessionEntity();
    savedSession.setSessionId(UUID.randomUUID());
    savedSession.setSlot(slot);
    savedSession.setClient(client);
    savedSession.setDomain(leadershipDomain);
    savedSession.setTopic("Executive presence");
    savedSession.setStatus(SessionStatus.CONFIRMED);

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));
    when(slotRepository.findByIdWithLock(slotId)).thenReturn(Optional.of(slot));
    when(sessionRepository.existsBySlot_SlotIdAndStatusNot(slotId, SessionStatus.CANCELLED))
        .thenReturn(false);
    when(domainRepository.findByCodeIgnoreCase("LEADERSHIP"))
        .thenReturn(Optional.of(leadershipDomain));
    when(sessionRepository.save(any(SessionEntity.class))).thenReturn(savedSession);

    BlindMatchCommand paidCommand =
        new BlindMatchCommand(
            userId,
            BookingType.PAID,
            coachId,
            slotId,
            "LEADERSHIP",
            "Executive presence",
            null,
            null);

    BlindMatchResult result = sessionService.scheduleBlindMatch(paidCommand);

    assertNotNull(result);
    assertEquals(savedSession.getSessionId(), result.sessionId());
    assertEquals(slotId, result.slotId());
    assertEquals(coachId, result.coachId());
    assertEquals("Coach Daniel", result.coachAlias());
    assertEquals("MCC", result.coachIcfLevel());
    assertEquals("LEADERSHIP", result.domainCode());
    assertEquals("Executive presence", result.topic());
    assertEquals(BookingType.PAID, result.bookingType());
    assertEquals("CONFIRMED", result.status());
    assertTrue(result.awaitingCheckout());
    assertFalse(result.isProBono());
    assertEquals(6, result.freeSessionsUsed());
    assertNotNull(result.nextFreeSessionAvailableAt());

    verify(clientRepository, never()).save(any(ClientEntity.class));

    // Also test paid booking with blank strugglePrompt and null domain (defaults topic) + null lastFreeSessionAt
    client.setFreeSessionsCount(null);
    client.setLastFreeSessionAt(null);
    BlindMatchCommand paidDefaultTopicCommand =
        new BlindMatchCommand(userId, BookingType.PAID, coachId, slotId, null, "   ", null, null);
    BlindMatchResult defaultTopicResult = sessionService.scheduleBlindMatch(paidDefaultTopicCommand);
    assertEquals(0, defaultTopicResult.freeSessionsUsed());
    assertNull(defaultTopicResult.nextFreeSessionAvailableAt());
  }

  @Test
  @DisplayName("scheduleBlindMatch paid booking validation and conflict scenarios")
  void testSchedulePaidBookingValidationAndConflicts() {
    final UUID userId = UUID.randomUUID();
    final UUID coachId = UUID.randomUUID();
    final UUID slotId = UUID.randomUUID();

    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));

    // 1. Missing coachId or slotId
    assertThrows(
        IllegalArgumentException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, null, slotId, null, "Topic", null, null)));
    assertThrows(
        IllegalArgumentException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, null, null, "Topic", null, null)));

    // 2. Slot not found
    when(slotRepository.findByIdWithLock(slotId)).thenReturn(Optional.empty());
    assertThrows(
        NoAvailableSlotsException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));

    // 3. Slot has null template or inactive template or belongs to a different coach
    SlotEntity invalidSlot = new SlotEntity();
    invalidSlot.setSlotId(slotId);
    when(slotRepository.findByIdWithLock(slotId)).thenReturn(Optional.of(invalidSlot));
    assertThrows(
        IllegalArgumentException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));

    AvailabilityTemplateEntity template = new AvailabilityTemplateEntity();
    template.setActive(false);
    invalidSlot.setAvailabilityTemplate(template);
    assertThrows(
        IllegalArgumentException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));

    template.setActive(true);
    assertThrows(
        IllegalArgumentException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));

    CoachEntity otherCoach = new CoachEntity();
    otherCoach.setCoachId(UUID.randomUUID());
    template.setCoach(otherCoach);
    assertThrows(
        IllegalArgumentException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));

    // 4. Slot already booked in active session
    CoachEntity validCoach = new CoachEntity();
    validCoach.setCoachId(coachId);
    template.setCoach(validCoach);
    when(sessionRepository.existsBySlot_SlotIdAndStatusNot(slotId, SessionStatus.CANCELLED))
        .thenReturn(true);
    assertThrows(
        SlotAlreadyBookedException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));

    // 5. Concurrent save throwing DataIntegrityViolationException translates to SlotAlreadyBookedException
    when(sessionRepository.existsBySlot_SlotIdAndStatusNot(slotId, SessionStatus.CANCELLED))
        .thenReturn(false);
    when(sessionRepository.save(any(SessionEntity.class)))
        .thenThrow(new DataIntegrityViolationException("Duplicate active slot"));
    assertThrows(
        SlotAlreadyBookedException.class,
        () ->
            sessionService.scheduleBlindMatch(
                new BlindMatchCommand(
                    userId, BookingType.PAID, coachId, slotId, null, "Topic", null, null)));
  }
}
