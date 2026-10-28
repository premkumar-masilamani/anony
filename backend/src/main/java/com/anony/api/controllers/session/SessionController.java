package com.anony.api.controllers.session;

import com.anony.api.dtos.auth.ErrorResponse;
import com.anony.api.dtos.session.BlindMatchRequest;
import com.anony.api.dtos.session.BlindMatchResponse;
import com.anony.api.dtos.session.QuotaExceededErrorResponse;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.domain.session.BlindMatchCommand;
import com.anony.domain.session.BlindMatchResult;
import com.anony.domain.session.BookingType;
import com.anony.domain.session.NoAvailableSlotsException;
import com.anony.domain.session.QuotaExceededException;
import com.anony.domain.session.SessionService;
import com.anony.domain.session.SlotAlreadyBookedException;
import com.anony.persistence.enums.UserRole;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller managing unified coaching session bookings ({@code POST /api/v1/sessions}),
 * supporting both automated pro-bono blind matches and direct paid coach/slot reservations.
 */
@RestController
@RequestMapping("/api/v1/sessions")
public class SessionController {

  private static final Logger LOGGER = LoggerFactory.getLogger(SessionController.class);

  private final SessionService sessionService;

  /**
   * Constructs session controller with required session service.
   *
   * @param sessionService service managing session bookings and blind matches
   */
  public SessionController(SessionService sessionService) {
    this.sessionService = sessionService;
  }

  /**
   * Creates a coaching session (either an automated pro-bono blind match or a paid coach/slot
   * reservation) for an authenticated client via the unified RESTful {@code POST /api/v1/sessions}
   * endpoint.
   *
   * @param authenticatedUser security principal representing the authenticated client
   * @param blindMatchRequest unified session booking parameters
   * @return confirmed session booking response
   */
  @PostMapping
  public ResponseEntity<BlindMatchResponse> scheduleBlindMatch(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser,
      @Valid @RequestBody BlindMatchRequest blindMatchRequest) {
    if (authenticatedUser != null) {
      if (authenticatedUser.role() == UserRole.CLIENT) {
        if (blindMatchRequest != null) {
          BookingType resolvedBookingType = resolveBookingType(blindMatchRequest);
          LOGGER.info(
              "Received POST /api/v1/sessions request from userId={}"
                  + " (bookingType={}, coachId={}, slotId={}, domainCode={}, preferredDate={}, preferredTimeWindow={})",
              authenticatedUser.userId(),
              resolvedBookingType,
              blindMatchRequest.coachId(),
              blindMatchRequest.slotId(),
              blindMatchRequest.domainCode(),
              blindMatchRequest.preferredDate(),
              blindMatchRequest.preferredTimeWindow());

          BlindMatchCommand command =
              new BlindMatchCommand(
                  authenticatedUser.userId(),
                  resolvedBookingType,
                  blindMatchRequest.coachId(),
                  blindMatchRequest.slotId(),
                  blindMatchRequest.domainCode(),
                  blindMatchRequest.strugglePrompt(),
                  blindMatchRequest.preferredTimeWindow(),
                  blindMatchRequest.preferredDate());

          BlindMatchResult matchResult = sessionService.scheduleBlindMatch(command);
          LOGGER.info(
              "Scheduled {} sessionId={} for userId={} with coachAlias={} at {}",
              matchResult.bookingType(),
              matchResult.sessionId(),
              authenticatedUser.userId(),
              matchResult.coachAlias(),
              matchResult.scheduledTime());

          return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(matchResult));
        } else {
          LOGGER.warn(
              "Rejected null session booking request payload from userId={}",
              authenticatedUser.userId());
          return ResponseEntity.badRequest().build();
        }
      } else {
        LOGGER.warn(
            "Forbidden POST /api/v1/sessions request from non-client userId={} (role={})",
            authenticatedUser.userId(),
            authenticatedUser.role());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }
    } else {
      LOGGER.warn("Unauthorized POST /api/v1/sessions request without principal.");
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
  }

  /**
   * Translates fair-use quota exceeded exceptions into HTTP 409 Conflict error responses.
   *
   * @param quotaExceededException exception containing quota violation details
   * @return structured quota error response
   */
  @ExceptionHandler(QuotaExceededException.class)
  public ResponseEntity<QuotaExceededErrorResponse> handleQuotaExceeded(
      QuotaExceededException quotaExceededException) {
    LOGGER.warn(
        "Returning 409 Conflict (FREE_SESSION_QUOTA_EXCEEDED: reason={}, used={}/{}, daysRemaining={})",
        quotaExceededException.getReason(),
        quotaExceededException.getFreeSessionsUsed(),
        quotaExceededException.getMaxFreeSessions(),
        quotaExceededException.getDaysRemaining());
    QuotaExceededErrorResponse errorPayload =
        new QuotaExceededErrorResponse(
            "FREE_SESSION_QUOTA_EXCEEDED",
            quotaExceededException.getReason(),
            quotaExceededException.getMessage(),
            quotaExceededException.getDaysRemaining(),
            quotaExceededException.getFreeSessionsUsed(),
            quotaExceededException.getMaxFreeSessions(),
            quotaExceededException.getSuggestedAction());

    return ResponseEntity.status(HttpStatus.CONFLICT).body(errorPayload);
  }

  /**
   * Translates slot lock contention or already-booked slot exceptions into HTTP 409 Conflict.
   *
   * @param slotAlreadyBookedException exception caught when slot is already booked
   * @return error response
   */
  @ExceptionHandler(SlotAlreadyBookedException.class)
  public ResponseEntity<ErrorResponse> handleSlotAlreadyBooked(
      SlotAlreadyBookedException slotAlreadyBookedException) {
    LOGGER.warn(
        "Returning 409 Conflict from SessionController: {}",
        slotAlreadyBookedException.getMessage());
    return ResponseEntity.status(HttpStatus.CONFLICT)
        .body(new ErrorResponse(slotAlreadyBookedException.getMessage()));
  }

  /**
   * Handles no available slots exceptions returning 404 Not Found.
   *
   * @param noAvailableSlotsException exception caught
   * @return error response
   */
  @ExceptionHandler(NoAvailableSlotsException.class)
  public ResponseEntity<ErrorResponse> handleNoAvailableSlots(
      NoAvailableSlotsException noAvailableSlotsException) {
    LOGGER.warn(
        "Returning 404 Not Found from SessionController: {}",
        noAvailableSlotsException.getMessage());
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorResponse(noAvailableSlotsException.getMessage()));
  }

  /**
   * Handles invalid argument exceptions returning 400 Bad Request.
   *
   * @param illegalArgumentException exception caught
   * @return error response
   */
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ErrorResponse> handleIllegalArgument(
      IllegalArgumentException illegalArgumentException) {
    LOGGER.warn(
        "Returning 400 Bad Request from SessionController: {}",
        illegalArgumentException.getMessage());
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
        .body(new ErrorResponse(illegalArgumentException.getMessage()));
  }

  /**
   * Handles missing entity or state exceptions returning 404 Not Found.
   *
   * @param illegalStateException exception caught
   * @return error response
   */
  @ExceptionHandler(IllegalStateException.class)
  public ResponseEntity<ErrorResponse> handleIllegalState(
      IllegalStateException illegalStateException) {
    LOGGER.warn(
        "Returning 404 Not Found from SessionController: {}",
        illegalStateException.getMessage());
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorResponse(illegalStateException.getMessage()));
  }

  private BookingType resolveBookingType(BlindMatchRequest blindMatchRequest) {
    if (blindMatchRequest.bookingType() != null) {
      return blindMatchRequest.bookingType();
    } else if (blindMatchRequest.isProBono() != null) {
      if (Boolean.TRUE.equals(blindMatchRequest.isProBono())) {
        return BookingType.FREE;
      } else {
        return BookingType.PAID;
      }
    } else if (blindMatchRequest.slotId() != null || blindMatchRequest.coachId() != null) {
      return BookingType.PAID;
    } else {
      return BookingType.FREE;
    }
  }

  private BlindMatchResponse toResponse(BlindMatchResult matchResult) {
    return new BlindMatchResponse(
        matchResult.sessionId(),
        matchResult.slotId(),
        matchResult.coachId(),
        matchResult.coachAlias(),
        matchResult.coachIcfLevel(),
        matchResult.domainCode(),
        matchResult.topic(),
        matchResult.scheduledTime(),
        matchResult.endTime(),
        matchResult.bookingType(),
        matchResult.status(),
        matchResult.awaitingCheckout(),
        matchResult.isProBono(),
        matchResult.freeSessionsUsed(),
        matchResult.maxFreeSessions(),
        matchResult.nextFreeSessionAvailableAt());
  }
}
