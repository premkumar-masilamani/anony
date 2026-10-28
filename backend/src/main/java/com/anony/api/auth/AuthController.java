package com.anony.api.auth;

import com.anony.api.dtos.auth.ErrorResponse;
import com.anony.api.dtos.auth.LoginRequest;
import com.anony.api.dtos.auth.LoginResponse;
import com.anony.api.dtos.auth.LogoutResponse;
import com.anony.api.dtos.auth.UserSummaryDto;
import com.anony.api.dtos.client.ClientRegistrationRequest;
import com.anony.domain.auth.AuthService;
import com.anony.domain.auth.AuthenticationResult;
import com.anony.domain.client.ClientRegistrationCommand;
import com.anony.domain.client.ClientService;
import com.anony.domain.security.AuthenticatedUser;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller exposing user authentication (login, register) and session termination (logout) endpoints.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

  private static final Logger LOGGER = LoggerFactory.getLogger(AuthController.class);

  private final AuthService authService;
  private final ClientService clientService;

  /**
   * Constructs the authentication controller.
   *
   * @param authService service for managing authentication and sessions
   * @param clientService service for managing client registration
   */
  public AuthController(AuthService authService, ClientService clientService) {
    this.authService = authService;
    this.clientService = clientService;
  }

  /**
   * Registers a new client profile and issues a signed Bearer JWT.
   *
   * @param clientRegistrationRequest client registration details
   * @return response containing token and user summary
   */
  @PostMapping("/register")
  public ResponseEntity<LoginResponse> register(
      @Valid @RequestBody ClientRegistrationRequest clientRegistrationRequest) {
    LOGGER.info("Received client registration request for email={}", clientRegistrationRequest.email());
    ClientRegistrationCommand command =
        new ClientRegistrationCommand(
            clientRegistrationRequest.email(),
            clientRegistrationRequest.password(),
            clientRegistrationRequest.firstName(),
            clientRegistrationRequest.lastName(),
            clientRegistrationRequest.alias());

    clientService.registerClient(command);

    AuthenticationResult authenticationResult =
        authService.authenticate(
            clientRegistrationRequest.email(), clientRegistrationRequest.password());

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

    LOGGER.info(
        "Completed client registration and issued JWT for userId={}",
        authenticationResult.userId());
    return ResponseEntity.status(HttpStatus.CREATED).body(loginResponse);
  }

  /**
   * Authenticates user credentials and issues a signed Bearer JWT.
   *
   * @param loginRequest login credentials
   * @return response containing token and user summary
   */
  @PostMapping("/login")
  public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
    LOGGER.info("Received login request for email={}", loginRequest.email());
    AuthenticationResult authenticationResult =
        authService.authenticate(loginRequest.email(), loginRequest.password());

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
  }

  /**
   * Terminates active session and invalidates the Bearer token in the database.
   *
   * @param authenticatedUser current authenticated security principal
   * @return logout confirmation
   */
  @PostMapping("/logout")
  public ResponseEntity<LogoutResponse> logout(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser) {
    if (authenticatedUser != null) {
      LOGGER.info("Received logout request for userId={}", authenticatedUser.userId());
      authService.logout(authenticatedUser.userId());
      return ResponseEntity.ok(new LogoutResponse("Logged out successfully"));
    } else {
      LOGGER.warn("Rejected unauthenticated logout request.");
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
  }

  /**
   * Handles authentication exceptions returning 401 Unauthorized.
   *
   * @param badCredentialsException the credentials exception
   * @return error response
   */
  @ExceptionHandler(BadCredentialsException.class)
  public ResponseEntity<ErrorResponse> handleBadCredentials(
      BadCredentialsException badCredentialsException) {
    LOGGER.warn("Returning 401 Unauthorized from AuthController: {}", badCredentialsException.getMessage());
    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
        .body(new ErrorResponse(badCredentialsException.getMessage()));
  }

  /**
   * Handles illegal argument exceptions returning 400 Bad Request.
   *
   * @param illegalArgumentException the argument exception
   * @return error response
   */
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ErrorResponse> handleIllegalArgument(
      IllegalArgumentException illegalArgumentException) {
    LOGGER.warn("Returning 400 Bad Request from AuthController: {}", illegalArgumentException.getMessage());
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
        .body(new ErrorResponse(illegalArgumentException.getMessage()));
  }
}

