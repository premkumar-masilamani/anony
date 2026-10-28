package com.anony.domain.session;

import com.anony.persistence.entities.ClientEntity;
import com.anony.persistence.entities.CoachEntity;
import com.anony.persistence.entities.SessionEntity;
import com.anony.persistence.entities.SlotEntity;
import com.anony.persistence.enums.SessionStatus;
import com.anony.persistence.repositories.ClientRepository;
import com.anony.persistence.repositories.SessionRepository;
import com.anony.persistence.repositories.SlotRepository;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Default implementation of {@link SessionService} enforcing 14-day cadence cooldowns,
 * 6-session lifetime caps, and atomic slot claiming for pro-bono blind matches.
 */
@Service
public class DefaultSessionService implements SessionService {

  private static final Logger LOGGER = LoggerFactory.getLogger(DefaultSessionService.class);

  private static final int MAX_FREE_SESSIONS = 6;
  private static final long COOLDOWN_DAYS = 14L;
  private static final long COOLDOWN_SECONDS = 14L * 86400L;
  private static final String REGULAR_MODE_SUGGESTION =
      "SWITCH_TO_REGULAR_MODE_FOR_PAID_BOOKINGS";

  private final ClientRepository clientRepository;
  private final SlotRepository slotRepository;
  private final SessionRepository sessionRepository;

  /**
   * Constructs session service with required persistence repositories.
   *
   * @param clientRepository repository managing client entities and quota state
   * @param slotRepository repository managing bookable slots
   * @param sessionRepository repository managing session reservations
   */
  public DefaultSessionService(
      ClientRepository clientRepository,
      SlotRepository slotRepository,
      SessionRepository sessionRepository) {
    this.clientRepository = clientRepository;
    this.slotRepository = slotRepository;
    this.sessionRepository = sessionRepository;
  }

  @Override
  @Transactional
  public BlindMatchResult scheduleBlindMatch(BlindMatchCommand blindMatchCommand) {
    if (blindMatchCommand != null) {
      if (StringUtils.isNotBlank(blindMatchCommand.strugglePrompt())) {
        LOGGER.debug(
            "Evaluating blind-match eligibility for userId={} (preferredDate={}, preferredTimeWindow={})",
            blindMatchCommand.userId(),
            blindMatchCommand.preferredDate(),
            blindMatchCommand.preferredTimeWindow());
        Optional<ClientEntity> clientOptional =
            clientRepository.findByUser_UserId(blindMatchCommand.userId());

        if (clientOptional.isPresent()) {
          ClientEntity clientEntity = clientOptional.get();
          int currentSessionsUsed = clientEntity.getFreeSessionsCount() == null
              ? 0
              : clientEntity.getFreeSessionsCount();

          boolean hasRemainingLifetimeCap = currentSessionsUsed < MAX_FREE_SESSIONS;

          if (hasRemainingLifetimeCap) {
            Instant lastSessionTimestamp = clientEntity.getLastFreeSessionAt();
            Instant currentInstant = Instant.now();

            boolean isCadenceCooldownExpired = lastSessionTimestamp == null
                || Duration.between(lastSessionTimestamp, currentInstant).getSeconds()
                    >= COOLDOWN_SECONDS;

            if (isCadenceCooldownExpired) {
              SlotEntity matchedSlot = resolveAvailableSlot(
                  blindMatchCommand.preferredDate(),
                  blindMatchCommand.preferredTimeWindow(),
                  currentInstant);

              final CoachEntity coachEntity = matchedSlot.getAvailabilityTemplate().getCoach();
              final String coachIcfLevel = resolveCoachIcfLevel(coachEntity);
              final String coachAlias = resolveCoachAlias(coachEntity);

              SessionEntity sessionEntity = new SessionEntity();
              sessionEntity.setSlot(matchedSlot);
              sessionEntity.setClient(clientEntity);
              sessionEntity.setTopic(blindMatchCommand.strugglePrompt().trim());
              sessionEntity.setStatus(SessionStatus.CONFIRMED);

              final SessionEntity savedSession = sessionRepository.save(sessionEntity);

              int updatedFreeSessionsUsed = currentSessionsUsed + 1;
              clientEntity.setFreeSessionsCount(updatedFreeSessionsUsed);
              clientEntity.setLastFreeSessionAt(currentInstant);
              clientRepository.save(clientEntity);

              Instant nextSessionAvailableTimestamp =
                  currentInstant.plus(COOLDOWN_DAYS, ChronoUnit.DAYS);

              LOGGER.info(
                  "Confirmed pro-bono blind match sessionId={} for clientId={} with coachAlias={} at {} (used {}/{})",
                  savedSession.getSessionId(),
                  clientEntity.getClientId(),
                  coachAlias,
                  matchedSlot.getStartAt(),
                  updatedFreeSessionsUsed,
                  MAX_FREE_SESSIONS);

              return new BlindMatchResult(
                  savedSession.getSessionId(),
                  coachAlias,
                  coachIcfLevel,
                  savedSession.getTopic(),
                  matchedSlot.getStartAt(),
                  savedSession.getStatus().name(),
                  true,
                  updatedFreeSessionsUsed,
                  MAX_FREE_SESSIONS,
                  nextSessionAvailableTimestamp);
            } else {
              long elapsedSeconds =
                  Duration.between(lastSessionTimestamp, currentInstant).getSeconds();
              long remainingSeconds = COOLDOWN_SECONDS - elapsedSeconds;
              int daysRemaining = (int) Math.ceil(remainingSeconds / 86400.0);

              LOGGER.warn(
                  "Blind match rejected for clientId={}: 14-day cooldown active ({} days remaining)",
                  clientEntity.getClientId(),
                  daysRemaining);
              throw new QuotaExceededException(
                  "You can book 1 free pro-bono session every 14 days. Your next free session unlocks in "
                      + daysRemaining
                      + " days.",
                  "COOLDOWN_ACTIVE",
                  daysRemaining,
                  currentSessionsUsed,
                  MAX_FREE_SESSIONS,
                  REGULAR_MODE_SUGGESTION);
            }
          } else {
            LOGGER.warn(
                "Blind match rejected for clientId={}: lifetime cap of {} free sessions reached",
                clientEntity.getClientId(),
                MAX_FREE_SESSIONS);
            throw new QuotaExceededException(
                "You have completed all 6 free pro-bono sessions. Switch to Regular Mode in your profile to browse coaches and schedule paid sessions.",
                "LIFETIME_CAP_REACHED",
                0,
                MAX_FREE_SESSIONS,
                MAX_FREE_SESSIONS,
                REGULAR_MODE_SUGGESTION);
          }
        } else {
          LOGGER.warn("Blind match failed: client profile not found for userId={}", blindMatchCommand.userId());
          throw new IllegalStateException(
              "Client profile not found for user: " + blindMatchCommand.userId());
        }
      } else {
        LOGGER.warn("Blind match rejected: struggle prompt was blank.");
        throw new IllegalArgumentException("Struggle prompt cannot be blank.");
      }
    } else {
      LOGGER.warn("Blind match rejected: command was null.");
      throw new IllegalArgumentException("Blind match command cannot be null.");
    }
  }

  private SlotEntity resolveAvailableSlot(
      LocalDate preferredDate,
      TimeWindow preferredTimeWindow,
      Instant currentInstant) {
    LocalDate targetDate = preferredDate == null ? LocalDate.now(ZoneOffset.UTC) : preferredDate;
    TimeWindow targetWindow =
        preferredTimeWindow == null ? TimeWindow.ANYTIME : preferredTimeWindow;

    LocalTime startTime = switch (targetWindow) {
      case MORNING -> LocalTime.of(9, 0);
      case AFTERNOON -> LocalTime.of(12, 0);
      case EVENING -> LocalTime.of(17, 0);
      case ANYTIME -> LocalTime.of(0, 0);
    };

    LocalTime endTime = switch (targetWindow) {
      case MORNING -> LocalTime.of(12, 0);
      case AFTERNOON -> LocalTime.of(17, 0);
      case EVENING -> LocalTime.of(21, 0);
      case ANYTIME -> LocalTime.of(23, 59, 59);
    };

    Instant windowStart = targetDate.atTime(startTime).toInstant(ZoneOffset.UTC);
    Instant windowEnd = targetDate.atTime(endTime).toInstant(ZoneOffset.UTC);

    LOGGER.debug(
        "Searching available pro-bono slots in primary window [{} -> {}] (targetWindow={})",
        windowStart,
        windowEnd,
        targetWindow);
    List<SlotEntity> slotsInWindow =
        slotRepository.findAvailableSlotsInWindow(windowStart, windowEnd);

    if (!slotsInWindow.isEmpty()) {
      SlotEntity selectedSlot = slotsInWindow.get(0);
      LOGGER.debug(
          "Matched slotId={} in primary window starting at {}",
          selectedSlot.getSlotId(),
          selectedSlot.getStartAt());
      return selectedSlot;
    } else {
      LOGGER.info(
          "No slots found in primary window [{} -> {}]; falling back to 30-day search from {}",
          windowStart,
          windowEnd,
          currentInstant);
      Instant fallbackSearchStart = currentInstant;
      Instant fallbackSearchEnd = currentInstant.plus(30, ChronoUnit.DAYS);
      List<SlotEntity> fallbackSlots =
          slotRepository.findAvailableSlotsInWindow(fallbackSearchStart, fallbackSearchEnd);

      if (!fallbackSlots.isEmpty()) {
        SlotEntity fallbackSlot = fallbackSlots.get(0);
        LOGGER.debug(
            "Matched fallback slotId={} starting at {}",
            fallbackSlot.getSlotId(),
            fallbackSlot.getStartAt());
        return fallbackSlot;
      } else {
        LOGGER.warn(
            "No available pro-bono coach slots found in primary window or 30-day fallback window.");
        throw new NoAvailableSlotsException(
            "No available pro-bono coach slots found for the requested time window.");
      }
    }
  }

  private String resolveCoachIcfLevel(CoachEntity coachEntity) {
    if (coachEntity != null) {
      if (Boolean.TRUE.equals(coachEntity.getIcfMcc())) {
        return "MCC";
      } else if (Boolean.TRUE.equals(coachEntity.getIcfPcc())) {
        return "PCC";
      } else if (Boolean.TRUE.equals(coachEntity.getIcfAcc())) {
        return "ACC";
      } else if (Boolean.TRUE.equals(coachEntity.getIcfActc())) {
        return "ACTC";
      } else {
        return "CERTIFIED";
      }
    } else {
      return "CERTIFIED";
    }
  }

  private String resolveCoachAlias(CoachEntity coachEntity) {
    if (coachEntity != null && StringUtils.isNotBlank(coachEntity.getFirstName())) {
      return "Coach " + coachEntity.getFirstName();
    } else {
      return "SereneGuide";
    }
  }
}
