package com.anony.api.controllers.coach;

import com.anony.api.dtos.auth.ErrorResponse;
import com.anony.api.dtos.auth.LoginRequest;
import com.anony.api.dtos.auth.LoginResponse;
import com.anony.api.dtos.auth.UserSummaryDto;
import com.anony.api.dtos.coach.CoachAvailabilitySlotDto;
import com.anony.api.dtos.coach.CoachProfileDto;
import com.anony.api.dtos.coach.CoachRegistrationRequest;
import com.anony.api.dtos.coach.CoachUpdateRequest;
import com.anony.domain.auth.AuthService;
import com.anony.domain.auth.AuthenticationResult;
import com.anony.domain.coach.CoachAvailabilitySlotDetails;
import com.anony.domain.coach.CoachProfileDetails;
import com.anony.domain.coach.CoachRegistrationCommand;
import com.anony.domain.coach.CoachService;
import com.anony.domain.coach.CoachUpdateCommand;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.persistence.enums.UserRole;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller managing coach registration, authentication, updates, profile verification status,
 * and availability slot discovery.
 */
@RestController
@RequestMapping("/api/v1/coaches")
public class CoachController {

  private final CoachService coachService;
  private final AuthService authService;

  /**
   * Constructs coach controller with required services.
   *
   * @param coachService service managing coach profiles and availabilities
   * @param authService service managing authentication sessions
   */
  public CoachController(CoachService coachService, AuthService authService) {
    this.coachService = coachService;
    this.authService = authService;
  }

  /**
   * Registers a new coach profile with ICF credential submission. Defaults is_verified to false.
   *
   * @param coachRegistrationRequest coach registration details
   * @return newly created coach profile details
   */
  @PostMapping("/register")
  public ResponseEntity<CoachProfileDto> register(
      @Valid @RequestBody CoachRegistrationRequest coachRegistrationRequest) {
    CoachRegistrationCommand command =
        new CoachRegistrationCommand(
            coachRegistrationRequest.email(),
            coachRegistrationRequest.password(),
            coachRegistrationRequest.firstName(),
            coachRegistrationRequest.lastName(),
            coachRegistrationRequest.photoUrl(),
            coachRegistrationRequest.gender(),
            coachRegistrationRequest.countryCode(),
            coachRegistrationRequest.timezone(),
            coachRegistrationRequest.biography(),
            coachRegistrationRequest.icfLevel(),
            coachRegistrationRequest.icfAcc(),
            coachRegistrationRequest.icfPcc(),
            coachRegistrationRequest.icfMcc(),
            coachRegistrationRequest.icfActc(),
            coachRegistrationRequest.credentialDetails(),
            coachRegistrationRequest.domainCodes(),
            coachRegistrationRequest.hourlyRate());

    CoachProfileDetails details = coachService.registerCoach(command);
    return ResponseEntity.status(HttpStatus.CREATED).body(toDto(details));
  }

  /**
   * Authenticates coach credentials and issues a signed Bearer JWT token.
   *
   * @param loginRequest coach login credentials
   * @return login response containing token and user summary
   */
  @PostMapping("/login")
  public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
    AuthenticationResult authenticationResult =
        authService.authenticate(loginRequest.email(), loginRequest.password());

    if (authenticationResult.role() == UserRole.COACH) {
      UserSummaryDto userSummaryDto =
          new UserSummaryDto(
              authenticationResult.userId(),
              authenticationResult.email(),
              authenticationResult.role());

      LoginResponse loginResponse =
          new LoginResponse(
              authenticationResult.token(),
              authenticationResult.expiresIn(),
              userSummaryDto);

      return ResponseEntity.ok(loginResponse);
    } else {
      throw new BadCredentialsException("Account is not registered as a coach.");
    }
  }

  /**
   * Retrieves profile details and current verification state for the authenticated coach.
   *
   * @param authenticatedUser authenticated security principal
   * @return current coach profile details
   */
  @GetMapping("/me")
  public ResponseEntity<CoachProfileDto> getProfile(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser) {
    if (authenticatedUser != null) {
      if (authenticatedUser.role() == UserRole.COACH) {
        CoachProfileDetails details =
            coachService.getCoachProfileByUserId(authenticatedUser.userId());
        return ResponseEntity.ok(toDto(details));
      } else {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }
    } else {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
  }

  /**
   * Updates profile details and credential submission for the authenticated coach.
   *
   * @param authenticatedUser authenticated security principal
   * @param coachUpdateRequest updated profile details
   * @return updated coach profile details
   */
  @PutMapping("/me")
  public ResponseEntity<CoachProfileDto> updateProfile(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser,
      @Valid @RequestBody CoachUpdateRequest coachUpdateRequest) {
    if (authenticatedUser != null) {
      if (authenticatedUser.role() == UserRole.COACH) {
        CoachUpdateCommand command =
            new CoachUpdateCommand(
                coachUpdateRequest.firstName(),
                coachUpdateRequest.lastName(),
                coachUpdateRequest.photoUrl(),
                coachUpdateRequest.gender(),
                coachUpdateRequest.countryCode(),
                coachUpdateRequest.timezone(),
                coachUpdateRequest.biography(),
                coachUpdateRequest.icfLevel(),
                coachUpdateRequest.icfAcc(),
                coachUpdateRequest.icfPcc(),
                coachUpdateRequest.icfMcc(),
                coachUpdateRequest.icfActc(),
                coachUpdateRequest.credentialDetails(),
                coachUpdateRequest.domainCodes(),
                coachUpdateRequest.hourlyRate());

        CoachProfileDetails details =
            coachService.updateCoachProfile(authenticatedUser.userId(), command);
        return ResponseEntity.ok(toDto(details));
      } else {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }
    } else {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
  }

  /**
   * Retrieves unbooked availability slots for a coach within an optional UTC date range.
   *
   * @param coachId unique coach identifier
   * @param from optional inclusive UTC start timestamp
   * @param to optional inclusive UTC end timestamp
   * @return list of unbooked availability slots
   */
  @GetMapping("/{id}/availabilities")
  public ResponseEntity<List<CoachAvailabilitySlotDto>> getCoachAvailabilities(
      @PathVariable("id") UUID coachId,
      @RequestParam(name = "from", required = false) Instant from,
      @RequestParam(name = "to", required = false) Instant to) {
    List<CoachAvailabilitySlotDetails> availableSlots =
        coachService.getCoachAvailabilities(coachId, from, to);
    return ResponseEntity.ok(toSlotDtos(availableSlots));
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
   * Handles not found exceptions returning 404 Not Found.
   *
   * @param illegalStateException exception caught
   * @return error response
   */
  @ExceptionHandler(IllegalStateException.class)
  public ResponseEntity<ErrorResponse> handleNotFound(
      IllegalStateException illegalStateException) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorResponse(illegalStateException.getMessage()));
  }

  /**
   * Handles bad credentials exceptions returning 401 Unauthorized.
   *
   * @param badCredentialsException exception caught
   * @return error response
   */
  @ExceptionHandler(BadCredentialsException.class)
  public ResponseEntity<ErrorResponse> handleBadCredentials(
      BadCredentialsException badCredentialsException) {
    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
        .body(new ErrorResponse(badCredentialsException.getMessage()));
  }

  private List<CoachAvailabilitySlotDto> toSlotDtos(
      List<CoachAvailabilitySlotDetails> slotDetailsList) {
    List<CoachAvailabilitySlotDto> slotDtos = new ArrayList<>();
    for (CoachAvailabilitySlotDetails slotDetails : slotDetailsList) {
      slotDtos.add(
          new CoachAvailabilitySlotDto(
              slotDetails.slotId(),
              slotDetails.coachId(),
              slotDetails.startAt(),
              slotDetails.endAt(),
              slotDetails.durationMinutes(),
              slotDetails.isFreePledge(),
              slotDetails.isBooked()));
    }
    return slotDtos;
  }

  private CoachProfileDto toDto(CoachProfileDetails details) {
    return new CoachProfileDto(
        details.coachId(),
        details.userId(),
        details.email(),
        details.firstName(),
        details.lastName(),
        details.photoUrl(),
        details.gender(),
        details.countryCode(),
        details.timezone(),
        details.biography(),
        details.icfLevel(),
        details.icfAcc(),
        details.icfPcc(),
        details.icfMcc(),
        details.icfActc(),
        details.credentialDetails(),
        details.hourlyRate(),
        details.isVerified(),
        details.isOnboarded(),
        details.domainCodes(),
        details.createdAt());
  }
}
