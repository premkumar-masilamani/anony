package com.anony.api.controllers.client;

import com.anony.api.dtos.auth.ErrorResponse;
import com.anony.api.dtos.client.ClientProfileDto;
import com.anony.api.dtos.client.UpdatePrivacyModeRequest;
import com.anony.domain.client.ClientProfileDetails;
import com.anony.domain.client.ClientService;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.persistence.enums.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller managing client profile lookups and anonymity mode state.
 */
@RestController
@RequestMapping("/api/v1/clients")
public class ClientController {

  private final ClientService clientService;

  /**
   * Constructs client controller with required client service.
   *
   * @param clientService service managing client profiles
   */
  public ClientController(ClientService clientService) {
    this.clientService = clientService;
  }

  /**
   * Retrieves profile details for the authenticated client.
   *
   * @param authenticatedUser authenticated security principal
   * @return current client profile details
   */
  @GetMapping("/me")
  public ResponseEntity<ClientProfileDto> getProfile(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser) {
    if (authenticatedUser != null) {
      if (authenticatedUser.role() == UserRole.CLIENT) {
        ClientProfileDetails details =
            clientService.getClientProfileByUserId(authenticatedUser.userId());
        return ResponseEntity.ok(toDto(details));
      } else {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
      }
    } else {
      return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
  }

  /**
   * Updates privacy and anonymity mode for the authenticated client via PATCH.
   *
   * @param authenticatedUser authenticated security principal
   * @param updatePrivacyModeRequest request payload containing desired anonymity mode
   * @return updated client profile details
   */
  @PatchMapping("/me/privacy-mode")
  public ResponseEntity<ClientProfileDto> patchPrivacyMode(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser,
      @Valid @RequestBody UpdatePrivacyModeRequest updatePrivacyModeRequest) {
    return handlePrivacyModeUpdate(authenticatedUser, updatePrivacyModeRequest);
  }

  /**
   * Updates privacy and anonymity mode for the authenticated client via PUT.
   *
   * @param authenticatedUser authenticated security principal
   * @param updatePrivacyModeRequest request payload containing desired anonymity mode
   * @return updated client profile details
   */
  @PutMapping("/me/privacy-mode")
  public ResponseEntity<ClientProfileDto> putPrivacyMode(
      @AuthenticationPrincipal AuthenticatedUser authenticatedUser,
      @Valid @RequestBody UpdatePrivacyModeRequest updatePrivacyModeRequest) {
    return handlePrivacyModeUpdate(authenticatedUser, updatePrivacyModeRequest);
  }

  private ResponseEntity<ClientProfileDto> handlePrivacyModeUpdate(
      AuthenticatedUser authenticatedUser,
      UpdatePrivacyModeRequest updatePrivacyModeRequest) {
    if (authenticatedUser != null) {
      if (authenticatedUser.role() == UserRole.CLIENT) {
        if (updatePrivacyModeRequest != null && updatePrivacyModeRequest.isAnonymousMode() != null) {
          ClientProfileDetails details = clientService.updatePrivacyMode(
              authenticatedUser.userId(),
              updatePrivacyModeRequest.isAnonymousMode());
          return ResponseEntity.ok(toDto(details));
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

  private ClientProfileDto toDto(ClientProfileDetails details) {
    return new ClientProfileDto(
        details.clientId(),
        details.userId(),
        details.email(),
        details.firstName(),
        details.lastName(),
        details.alias(),
        details.isAnonymous(),
        details.isOnboarded(),
        details.isAnonymousMode(),
        details.freeSessionsCount(),
        details.lastFreeSessionAt(),
        details.createdAt());
  }
}
