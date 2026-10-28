package com.anony.domain.session;

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
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Default implementation of {@link SessionService} enforcing atomic slot locking,
 * 14-day cadence cooldowns, 6-session lifetime caps for free blind matches, and direct
 * coach/slot reservations for paid bookings.
 */
@Service
public class DefaultSessionService implements SessionService {

  private static final Logger LOGGER = LoggerFactory.getLogger(DefaultSessionService.class);

  private static final int MAX_FREE_SESSIONS = 6;
  private static final long COOLDOWN_DAYS = 14L;
  private static final long COOLDOWN_SECONDS = 14L * 86400L;
  private static final String REGULAR_MODE_SUGGESTION =
      "SWITCH_TO_REGULAR_MODE_FOR_PAID_BOOKINGS";
  private static final String DEFAULT_PAID_SESSION_TOPIC = "1-on-1 Coaching Session";

  private final ClientRepository clientRepository;
  private final SlotRepository slotRepository;
  private final SessionRepository sessionRepository;
  private final DomainRepository domainRepository;

  /**
   * Constructs session service with required persistence repositories.
   *
   * @param clientRepository repository managing client entities and quota state
   * @param slotRepository repository managing bookable slots
   * @param sessionRepository repository managing session reservations
   * @param domainRepository repository managing coaching domains
   */
  public DefaultSessionService(
      ClientRepository clientRepository,
      SlotRepository slotRepository,
      SessionRepository sessionRepository,
      DomainRepository domainRepository) {
    this.clientRepository = clientRepository;
    this.slotRepository = slotRepository;
    this.sessionRepository = sessionRepository;
    this.domainRepository = domainRepository;
  }

  @Override
  @Transactional
  public BlindMatchResult scheduleBlindMatch(BlindMatchCommand blindMatchCommand) {
    if (blindMatchCommand != null) {
      BookingType resolvedBookingType =
          blindMatchCommand.bookingType() != null
              ? blindMatchCommand.bookingType()
              : BookingType.FREE;

      if (resolvedBookingType == BookingType.PAID) {
        return schedulePaidSession(blindMatchCommand);
      } else {
        return scheduleFreeBlindMatchSession(blindMatchCommand);
      }
    } else {
      LOGGER.warn("Session booking rejected: command was null.");
      throw new IllegalArgumentException("Session booking command cannot be null.");
    }
  }

  private BlindMatchResult scheduleFreeBlindMatchSession(BlindMatchCommand blindMatchCommand) {
    boolean hasStrugglePrompt = StringUtils.isNotBlank(blindMatchCommand.strugglePrompt());
    boolean hasDomainCode = StringUtils.isNotBlank(blindMatchCommand.domainCode());

    if (hasStrugglePrompt || hasDomainCode) {
      LOGGER.debug(
          "Evaluating free blind-match eligibility for userId={} (domainCode={}, preferredDate={}, preferredTimeWindow={})",
          blindMatchCommand.userId(),
          blindMatchCommand.domainCode(),
          blindMatchCommand.preferredDate(),
          blindMatchCommand.preferredTimeWindow());

      ClientEntity clientEntity = resolveClientProfile(blindMatchCommand.userId());
      DomainEntity resolvedDomain = resolveOptionalDomain(blindMatchCommand.domainCode());

      int currentSessionsUsed =
          clientEntity.getFreeSessionsCount() != null ? clientEntity.getFreeSessionsCount() : 0;
      boolean hasRemainingLifetimeCap = currentSessionsUsed < MAX_FREE_SESSIONS;

      if (hasRemainingLifetimeCap) {
        Instant lastSessionTimestamp = clientEntity.getLastFreeSessionAt();
        Instant currentInstant = Instant.now();

        boolean isCadenceCooldownExpired =
            lastSessionTimestamp == null
                || Duration.between(lastSessionTimestamp, currentInstant).getSeconds()
                    >= COOLDOWN_SECONDS;

        if (isCadenceCooldownExpired) {
          SlotEntity matchedSlot =
              resolveAvailableFreeSlot(
                  resolvedDomain,
                  blindMatchCommand.preferredDate(),
                  blindMatchCommand.preferredTimeWindow(),
                  currentInstant);

          final CoachEntity coachEntity = matchedSlot.getAvailabilityTemplate().getCoach();
          final String coachIcfLevel = resolveCoachIcfLevel(coachEntity);
          final String coachAlias = resolveCoachAlias(coachEntity);
          final UUID coachId = coachEntity != null ? coachEntity.getCoachId() : null;

          String resolvedTopic =
              hasStrugglePrompt
                  ? blindMatchCommand.strugglePrompt().trim()
                  : resolvedDomain.getName();

          SessionEntity sessionEntity = new SessionEntity();
          sessionEntity.setSlot(matchedSlot);
          sessionEntity.setClient(clientEntity);
          sessionEntity.setDomain(resolvedDomain);
          sessionEntity.setTopic(resolvedTopic);
          sessionEntity.setStatus(SessionStatus.CONFIRMED);

          final SessionEntity savedSession = persistSessionAtomically(sessionEntity);

          int updatedFreeSessionsUsed = currentSessionsUsed + 1;
          clientEntity.setFreeSessionsCount(updatedFreeSessionsUsed);
          clientEntity.setLastFreeSessionAt(currentInstant);
          clientRepository.save(clientEntity);

          Instant nextSessionAvailableTimestamp =
              currentInstant.plus(COOLDOWN_DAYS, ChronoUnit.DAYS);
          String resolvedDomainCode =
              resolvedDomain != null ? resolvedDomain.getCode() : null;

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
              matchedSlot.getSlotId(),
              coachId,
              coachAlias,
              coachIcfLevel,
              resolvedDomainCode,
              savedSession.getTopic(),
              matchedSlot.getStartAt(),
              matchedSlot.getEndAt(),
              BookingType.FREE,
              savedSession.getStatus().name(),
              false,
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
      LOGGER.warn("Free blind match rejected: both struggle prompt and domain code were blank.");
      throw new IllegalArgumentException(
          "Either struggle_prompt or domain_code must be provided for a free session booking.");
    }
  }

  private BlindMatchResult schedulePaidSession(BlindMatchCommand blindMatchCommand) {
    ClientEntity clientEntity = resolveClientProfile(blindMatchCommand.userId());

    if (blindMatchCommand.coachId() != null && blindMatchCommand.slotId() != null) {
      LOGGER.debug(
          "Attempting atomic paid slot booking for userId={}, coachId={}, slotId={}",
          blindMatchCommand.userId(),
          blindMatchCommand.coachId(),
          blindMatchCommand.slotId());

      Optional<SlotEntity> lockedSlotOptional =
          slotRepository.findByIdWithLock(blindMatchCommand.slotId());

      if (lockedSlotOptional.isPresent()) {
        SlotEntity lockedSlot = lockedSlotOptional.get();
        AvailabilityTemplateEntity templateEntity = lockedSlot.getAvailabilityTemplate();

        if (templateEntity != null
            && Boolean.TRUE.equals(templateEntity.getActive())
            && templateEntity.getCoach() != null
            && blindMatchCommand.coachId().equals(templateEntity.getCoach().getCoachId())) {
          boolean isSlotAvailable =
              !sessionRepository.existsBySlot_SlotIdAndStatusNot(
                  lockedSlot.getSlotId(), SessionStatus.CANCELLED);

          if (isSlotAvailable) {
            DomainEntity resolvedDomain = resolveOptionalDomain(blindMatchCommand.domainCode());
            String resolvedTopic =
                StringUtils.isNotBlank(blindMatchCommand.strugglePrompt())
                    ? blindMatchCommand.strugglePrompt().trim()
                    : DEFAULT_PAID_SESSION_TOPIC;

            SessionEntity sessionEntity = new SessionEntity();
            sessionEntity.setSlot(lockedSlot);
            sessionEntity.setClient(clientEntity);
            sessionEntity.setDomain(resolvedDomain);
            sessionEntity.setTopic(resolvedTopic);
            sessionEntity.setStatus(SessionStatus.CONFIRMED);

            SessionEntity savedSession = persistSessionAtomically(sessionEntity);

            CoachEntity coachEntity = templateEntity.getCoach();
            String coachAlias = resolveCoachAlias(coachEntity);
            String coachIcfLevel = resolveCoachIcfLevel(coachEntity);
            String resolvedDomainCode =
                resolvedDomain != null ? resolvedDomain.getCode() : null;
            int currentSessionsUsed =
                clientEntity.getFreeSessionsCount() != null
                    ? clientEntity.getFreeSessionsCount()
                    : 0;
            Instant nextFreeAvailableAt =
                clientEntity.getLastFreeSessionAt() != null
                    ? clientEntity.getLastFreeSessionAt().plus(COOLDOWN_DAYS, ChronoUnit.DAYS)
                    : null;

            LOGGER.info(
                "Locked and scheduled paid sessionId={} for clientId={} with coachId={} on slotId={}",
                savedSession.getSessionId(),
                clientEntity.getClientId(),
                coachEntity.getCoachId(),
                lockedSlot.getSlotId());

            return new BlindMatchResult(
                savedSession.getSessionId(),
                lockedSlot.getSlotId(),
                coachEntity.getCoachId(),
                coachAlias,
                coachIcfLevel,
                resolvedDomainCode,
                savedSession.getTopic(),
                lockedSlot.getStartAt(),
                lockedSlot.getEndAt(),
                BookingType.PAID,
                savedSession.getStatus().name(),
                true,
                false,
                currentSessionsUsed,
                MAX_FREE_SESSIONS,
                nextFreeAvailableAt);
          } else {
            LOGGER.warn(
                "Paid booking rejected: slotId={} is already booked in an active session.",
                lockedSlot.getSlotId());
            throw new SlotAlreadyBookedException("The requested slot is already booked.");
          }
        } else {
          LOGGER.warn(
              "Paid booking rejected: slotId={} does not belong to active coachId={}",
              blindMatchCommand.slotId(),
              blindMatchCommand.coachId());
          throw new IllegalArgumentException(
              "Requested slot does not belong to the specified active coach.");
        }
      } else {
        LOGGER.warn(
            "Paid booking rejected: slotId={} not found.",
            blindMatchCommand.slotId());
        throw new NoAvailableSlotsException(
            "Requested slot not found: " + blindMatchCommand.slotId());
      }
    } else {
      LOGGER.warn(
          "Paid booking rejected: missing coachId={} or slotId={}",
          blindMatchCommand.coachId(),
          blindMatchCommand.slotId());
      throw new IllegalArgumentException(
          "Both coach_id and slot_id are required for a paid session booking.");
    }
  }

  private ClientEntity resolveClientProfile(UUID userId) {
    Optional<ClientEntity> clientOptional = clientRepository.findByUser_UserId(userId);
    if (clientOptional.isPresent()) {
      return clientOptional.get();
    } else {
      LOGGER.warn("Session booking failed: client profile not found for userId={}", userId);
      throw new IllegalStateException("Client profile not found for user: " + userId);
    }
  }

  private DomainEntity resolveOptionalDomain(String domainCode) {
    if (StringUtils.isNotBlank(domainCode)) {
      String normalizedCode = domainCode.trim().toUpperCase(Locale.ROOT);
      Optional<DomainEntity> domainOptional =
          domainRepository.findByCodeIgnoreCase(normalizedCode);
      if (domainOptional.isPresent()) {
        return domainOptional.get();
      } else {
        LOGGER.warn("Session booking rejected: unknown domain_code={}", normalizedCode);
        throw new IllegalArgumentException("Unknown coaching domain code: " + normalizedCode);
      }
    } else {
      return null;
    }
  }

  private SessionEntity persistSessionAtomically(SessionEntity sessionEntity) {
    try {
      return sessionRepository.save(sessionEntity);
    } catch (DataIntegrityViolationException integrityException) {
      LOGGER.warn(
          "Concurrent slot lock contention detected when saving session: {}",
          integrityException.getMessage());
      throw new SlotAlreadyBookedException("The requested slot is already booked.");
    }
  }

  private SlotEntity resolveAvailableFreeSlot(
      DomainEntity domainEntity,
      LocalDate preferredDate,
      TimeWindow preferredTimeWindow,
      Instant currentInstant) {
    LocalDate targetDate = preferredDate != null ? preferredDate : LocalDate.now(ZoneOffset.UTC);
    TimeWindow targetWindow =
        preferredTimeWindow != null ? preferredTimeWindow : TimeWindow.ANYTIME;

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

    if (domainEntity != null) {
      LOGGER.debug(
          "Searching available free-pledge slots for domain={} in primary window [{} -> {}]",
          domainEntity.getCode(),
          windowStart,
          windowEnd);
      List<SlotEntity> domainSlots =
          slotRepository.findAvailableFreeSlotsByDomainInWindow(
              domainEntity.getCode(), windowStart, windowEnd);
      if (!domainSlots.isEmpty()) {
        SlotEntity matchedDomainSlot = domainSlots.get(0);
        LOGGER.debug(
            "Matched domain-filtered free slotId={} starting at {}",
            matchedDomainSlot.getSlotId(),
            matchedDomainSlot.getStartAt());
        return matchedDomainSlot;
      } else {
        LOGGER.debug(
            "No domain-specific free slots found in primary window for domain={}; broadening search.",
            domainEntity.getCode());
      }
    } else {
      LOGGER.debug("No domain filter specified for free blind match; searching all domains.");
    }

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
