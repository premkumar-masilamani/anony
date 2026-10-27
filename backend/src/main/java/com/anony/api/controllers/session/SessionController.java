package com.anony.api.controllers.session;

import com.anony.api.dtos.auth.ErrorResponse;
import com.anony.api.dtos.session.BlindMatchRequest;
import com.anony.api.dtos.session.BlindMatchResponse;
import com.anony.api.dtos.session.QuotaExceededErrorResponse;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.domain.session.BlindMatchCommand;
import com.anony.domain.session.BlindMatchResult;
import com.anony.domain.session.NoAvailableSlotsException;
import com.anony.domain.session.QuotaExceededException;
import com.anony.domain.session.SessionService;
import com.anony.persistence.enums.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller managing coaching sessions, bookings, and automated pro-bono blind matches.
 */
@RestController
@RequestMapping("/api/v1/sessions")
public class SessionController {

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
   * Schedules an automated pro-bono blind match session for an authenticated client.
   *
   * @param authenticatedUser security principal representing the authenticated client
   * @param blindMatchRequest requested session parameters including struggle prompt and time preferences
   * @return confirmed session booking response
   */
  @PostMapping("/blind-match")
  public ResponseEntity<BlindMatchResponse> scheduleBlindMatch(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser,
      @Valid @RequestBody BlindMatchRequest blindMatchRequest) {
    if (authenticatedUser != null) {
      if (authenticatedUser.role() == UserRole.CLIENT) {
        if (blindMatchRequest != null) {
          BlindMatchCommand command = new BlindMatchCommand(
              authenticatedUser.userId(),
              blindMatchRequest.strugglePrompt(),
              blindMatchRequest.preferredTimeWindow(),
              blindMatchRequest.preferredDate());

          BlindMatchResult matchResult = sessionService.scheduleBlindMatch(command);

          return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(matchResult));
        } else {
          return ResponseEntity.badRequest().build();
        }
      } else {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }
    } else {
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
    QuotaExceededErrorResponse errorPayload = new QuotaExceededErrorResponse(
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
   * Handles no available slots exceptions returning 404 Not Found.
   *
   * @param noAvailableSlotsException exception caught
   * @return error response
   */
  @ExceptionHandler(NoAvailableSlotsException.class)
  public ResponseEntity<ErrorResponse> handleNoAvailableSlots(
      NoAvailableSlotsException noAvailableSlotsException) {
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
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorResponse(illegalStateException.getMessage()));
  }

  private BlindMatchResponse toResponse(BlindMatchResult matchResult) {
    return new BlindMatchResponse(
        matchResult.sessionId(),
        matchResult.coachAlias(),
        matchResult.coachIcfLevel(),
        matchResult.topic(),
        matchResult.scheduledTime(),
        matchResult.status(),
        matchResult.isProBono(),
        matchResult.freeSessionsUsed(),
        matchResult.maxFreeSessions(),
        matchResult.nextFreeSessionAvailableAt());
  }
}
