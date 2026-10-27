package com.anony.domain.session;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.anony.persistence.entities.AvailabilityTemplateEntity;
import com.anony.persistence.entities.ClientEntity;
import com.anony.persistence.entities.CoachEntity;
import com.anony.persistence.entities.SessionEntity;
import com.anony.persistence.entities.SlotEntity;
import com.anony.persistence.enums.SessionStatus;
import com.anony.persistence.repositories.ClientRepository;
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

@ExtendWith(MockitoExtension.class)
class DefaultSessionServiceTest {

  @Mock
  private ClientRepository clientRepository;

  @Mock
  private SlotRepository slotRepository;

  @Mock
  private SessionRepository sessionRepository;

  private DefaultSessionService sessionService;

  @BeforeEach
  void setUp() {
    sessionService =
        new DefaultSessionService(clientRepository, slotRepository, sessionRepository);
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalArgumentException when command is null")
  void testScheduleBlindMatchNullCommand() {
    assertThrows(
        IllegalArgumentException.class,
        () -> sessionService.scheduleBlindMatch(null));
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalArgumentException when struggle prompt is blank")
  void testScheduleBlindMatchBlankPrompt() {
    UUID userId = UUID.randomUUID();
    BlindMatchCommand command =
        new BlindMatchCommand(userId, "   ", TimeWindow.EVENING, LocalDate.now());

    assertThrows(
        IllegalArgumentException.class,
        () -> sessionService.scheduleBlindMatch(command));
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw IllegalStateException when client is missing")
  void testScheduleBlindMatchClientNotFound() {
    UUID userId = UUID.randomUUID();
    BlindMatchCommand command =
        new BlindMatchCommand(userId, "Need leadership support", TimeWindow.MORNING, LocalDate.now());

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
        new BlindMatchCommand(userId, "Need support", TimeWindow.AFTERNOON, LocalDate.now());

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));

    QuotaExceededException ex =
        assertThrows(
            QuotaExceededException.class,
            () -> sessionService.scheduleBlindMatch(command));

    assertEquals("LIFETIME_CAP_REACHED", ex.getReason());
    assertEquals(0, ex.getDaysRemaining());
    assertEquals(6, ex.getFreeSessionsUsed());
    assertEquals(6, ex.getMaxFreeSessions());
  }

  @Test
  @DisplayName("scheduleBlindMatch should throw QuotaExceededException when 14-day cooldown is active")
  void testScheduleBlindMatchCooldownActive() {
    UUID userId = UUID.randomUUID();
    ClientEntity client = new ClientEntity();
    client.setClientId(UUID.randomUUID());
    client.setFreeSessionsCount(2);
    // Session completed 5 days ago (cooldown active for 9 more days)
    client.setLastFreeSessionAt(Instant.now().minus(5, ChronoUnit.DAYS));

    BlindMatchCommand command =
        new BlindMatchCommand(userId, "Need support", TimeWindow.EVENING, LocalDate.now());

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(client));

    QuotaExceededException ex =
        assertThrows(
            QuotaExceededException.class,
            () -> sessionService.scheduleBlindMatch(command));

    assertEquals("COOLDOWN_ACTIVE", ex.getReason());
    assertEquals(9, ex.getDaysRemaining());
    assertEquals(2, ex.getFreeSessionsUsed());
  }

  @Test
  @DisplayName("scheduleBlindMatch should match slot in requested window and confirm session")
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
            "Overwhelmed with executive burnout",
            TimeWindow.EVENING,
            LocalDate.now().plusDays(1));

    BlindMatchResult result = sessionService.scheduleBlindMatch(command);

    assertNotNull(result);
    assertEquals("Coach AuraGuide", result.coachAlias());
    assertEquals("PCC", result.coachIcfLevel());
    assertEquals("CONFIRMED", result.status());
    assertTrue(result.isProBono());
    assertEquals(1, result.freeSessionsUsed());
    assertEquals(6, result.maxFreeSessions());
    assertNotNull(result.nextFreeSessionAvailableAt());

    verify(clientRepository).save(client);
    verify(sessionRepository).save(any(SessionEntity.class));
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
    // First query (in window) returns empty list, second query (fallback) returns fallbackSlot
    when(slotRepository.findAvailableSlotsInWindow(any(Instant.class), any(Instant.class)))
        .thenReturn(Collections.emptyList())
        .thenReturn(List.of(fallbackSlot));
    when(sessionRepository.save(any(SessionEntity.class))).thenReturn(savedSession);
    when(clientRepository.save(any(ClientEntity.class))).thenReturn(client);

    BlindMatchCommand command =
        new BlindMatchCommand(userId, "Career transition", TimeWindow.MORNING, LocalDate.now());

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
        new BlindMatchCommand(userId, "Need urgent support", TimeWindow.ANYTIME, LocalDate.now());

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
        new BlindMatchCommand(userId, "Struggle", TimeWindow.AFTERNOON, null);

    BlindMatchResult result = sessionService.scheduleBlindMatch(command);
    assertEquals("ACC", result.coachIcfLevel());
    assertEquals("SereneGuide", result.coachAlias());
  }
}
