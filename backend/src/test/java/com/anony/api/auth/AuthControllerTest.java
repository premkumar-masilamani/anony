package com.anony.api.auth;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.anony.domain.auth.AuthService;
import com.anony.domain.auth.AuthenticationResult;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.persistence.enums.UserRole;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

  @Mock
  private AuthService authService;

  private MockMvc mockMvc;

  @BeforeEach
  void setUp() {
    SecurityContextHolder.clearContext();
    AuthController authController = new AuthController(authService);
    this.mockMvc =
        MockMvcBuilders.standaloneSetup(authController)
            .setCustomArgumentResolvers(
                new org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver())
            .build();
  }

  @Test
  @DisplayName("POST /api/v1/auth/login should return 200 OK with token on valid credentials")
  void testLoginSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    String email = "maya.raman@example.com";
    String password = "AnonyDemo#2026";
    String token = "mock.signed.jwt";
    long expiresIn = 2592000L;

    when(authService.authenticate(email, password))
        .thenReturn(new AuthenticationResult(userId, email, UserRole.COACH, token, expiresIn));

    String jsonPayload = "{\"email\": \"" + email + "\", \"password\": \"" + password + "\"}";

    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.token").value(token))
        .andExpect(jsonPath("$.expiresIn").value(expiresIn))
        .andExpect(jsonPath("$.user.userId").value(userId.toString()))
        .andExpect(jsonPath("$.user.email").value(email))
        .andExpect(jsonPath("$.user.role").value("COACH"));

    verify(authService).authenticate(email, password);
  }

  @Test
  @DisplayName("POST /api/v1/auth/login should return 401 Unauthorized when credentials invalid")
  void testLoginInvalidCredentialsReturns401() throws Exception {
    String email = "maya.raman@example.com";
    String password = "wrongPassword";

    when(authService.authenticate(email, password))
        .thenThrow(new BadCredentialsException("Invalid email or password."));

    String jsonPayload = "{\"email\": \"" + email + "\", \"password\": \"" + password + "\"}";

    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error").value("Invalid email or password."));
  }

  @Test
  @DisplayName("POST /api/v1/auth/login should return 400 Bad Request on invalid payload")
  void testLoginInvalidPayload() throws Exception {
    String jsonPayload = """
        {"email": "notanemail", "password": ""}
        """;

    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
        .andExpect(status().isBadRequest());
  }

  @Test
  @DisplayName("POST /api/v1/auth/login should return 400 Bad Request when IllegalArgumentException is thrown")
  void testLoginIllegalArgumentReturns400() throws Exception {
    String email = "maya.raman@example.com";
    String password = "AnonyDemo#2026";

    when(authService.authenticate(email, password))
        .thenThrow(new IllegalArgumentException("Illegal email parameter."));

    String jsonPayload = "{\"email\": \"" + email + "\", \"password\": \"" + password + "\"}";

    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("Illegal email parameter."));
  }

  @Test
  @DisplayName("POST /api/v1/auth/logout should return 200 OK and invalidate session")
  void testLogoutSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "maya.raman@example.com", UserRole.COACH, tokenId);

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, java.util.List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    mockMvc
        .perform(
            post("/api/v1/auth/logout")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message").value("Logged out successfully"));

    verify(authService).logout(eq(userId));
  }

  @Test
  @DisplayName("POST /api/v1/auth/logout should return 401 Unauthorized when unauthenticated")
  void testLogoutUnauthenticatedReturns401() throws Exception {
    mockMvc
        .perform(
            post("/api/v1/auth/logout")
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isUnauthorized());
  }
}
