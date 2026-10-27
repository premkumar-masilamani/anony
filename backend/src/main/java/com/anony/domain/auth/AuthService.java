package com.anony.domain.auth;

import java.util.UUID;

/**
 * Service contract for user authentication and session termination.
 */
public interface AuthService {

  /**
   * Authenticates a user using email and password, issuing an active session and Bearer token.
   *
   * @param email user email address
   * @param rawPassword plain text password
   * @return authentication result containing user details and issued Bearer token
   */
  AuthenticationResult authenticate(String email, String rawPassword);

  /**
   * Terminates the active session for the given user, invalidating their token in the database.
   *
   * @param userId unique user identifier
   */
  void logout(UUID userId);
}
