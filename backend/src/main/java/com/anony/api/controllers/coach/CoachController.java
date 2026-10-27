package com.anony.api.controllers.coach;

import com.anony.api.dtos.auth.ErrorResponse;
import com.anony.api.dtos.auth.LoginRequest;
import com.anony.api.dtos.auth.LoginResponse;
import com.anony.api.dtos.auth.UserSummaryDto;
import com.anony.api.dtos.coach.CoachProfileDto;
import com.anony.api.dtos.coach.CoachRegistrationRequest;
import com.anony.domain.auth.AuthService;
import com.anony.domain.auth.AuthenticationResult;
import com.anony.domain.coach.CoachProfileDetails;
import com.anony.domain.coach.CoachRegistrationCommand;
import com.anony.domain.coach.CoachService;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.persistence.enums.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller managing coach registration, authentication, and profile verification status.
 */
@RestController
@RequestMapping("/api/v1/coaches")
public class CoachController {

  private final CoachService coachService;
  private final AuthService authService;

  /**
   * Constructs coach controller with required services.
   *
   * @param coachService service managing coach profiles
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
            coachRegistrationRequest.icfLevel(),
            coachRegistrationRequest.credentialDetails(),
            coachRegistrationRequest.domainCodes(),
            coachRegistrationRequest.timezone(),
            coachRegistrationRequest.biography(),
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

  private CoachProfileDto toDto(CoachProfileDetails details) {
    return new CoachProfileDto(
        details.coachId(),
        details.userId(),
        details.email(),
        details.firstName(),
        details.lastName(),
        details.timezone(),
        details.biography(),
        details.icfLevel(),
        details.icfAcc(),
        details.icfPcc(),
        details.icfMcc(),
        details.icfActc(),
        details.credentialDetails(),
        details.isVerified(),
        details.isOnboarded(),
        details.domainCodes(),
        details.createdAt());
  }
}
