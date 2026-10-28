package com.anony.api.auth;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.anony.domain.auth.AuthService;
import com.anony.domain.auth.AuthenticationResult;
import com.anony.domain.client.ClientProfileDetails;
import com.anony.domain.client.ClientRegistrationCommand;
import com.anony.domain.client.ClientService;
import com.anony.domain.coach.CoachProfileDetails;
import com.anony.domain.coach.CoachRegistrationCommand;
import com.anony.domain.coach.CoachService;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.persistence.enums.UserRole;
import java.time.Instant;
import java.util.List;
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

  @Mock
  private ClientService clientService;

  @Mock
  private CoachService coachService;

  private MockMvc mockMvc;

  @BeforeEach
  void setUp() {
    SecurityContextHolder.clearContext();
    AuthController authController = new AuthController(authService, clientService, coachService);
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

  @Test
  @DisplayName("POST /api/v1/auth/register should create client and return 201 Created with auth token")
  void testRegisterClientSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID clientId = UUID.randomUUID();
    ClientProfileDetails clientProfileDetails =
        new ClientProfileDetails(
            clientId,
            userId,
            "newclient@example.com",
            "Anonymous",
            "Client",
            "Courageous Owl",
            true,
            false,
            true,
            0,
            null,
            Instant.now());

    when(clientService.registerClient(any(ClientRegistrationCommand.class)))
        .thenReturn(clientProfileDetails);

    AuthenticationResult authenticationResult =
        new AuthenticationResult(
            userId, "newclient@example.com", UserRole.CLIENT, "mock.jwt.token", 86400L);
    when(authService.authenticate("newclient@example.com", "SecurePassword#123"))
        .thenReturn(authenticationResult);

    String payload =
        """
        {
          "email": "newclient@example.com",
          "password": "SecurePassword#123",
          "alias": "Courageous Owl"
        }
        """;

    mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.token").value("mock.jwt.token"))
        .andExpect(jsonPath("$.user.email").value("newclient@example.com"))
        .andExpect(jsonPath("$.user.role").value("CLIENT"));
  }

  @Test
  @DisplayName("POST /api/v1/auth/register should create coach when role or coach credentials are provided and return 201 Created with token")
  void testRegisterCoachSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();
    CoachProfileDetails coachProfileDetails =
        new CoachProfileDetails(
            coachId,
            userId,
            "coach@example.com",
            "Maya",
            "Raman",
            "Asia/Kolkata",
            "Career coach",
            "PCC",
            false,
            true,
            false,
            false,
            "ICF-PCC-1029",
            false,
            false,
            List.of("CAREER", "BURNOUT"),
            Instant.now());

    when(coachService.registerCoach(any(CoachRegistrationCommand.class)))
        .thenReturn(coachProfileDetails);

    AuthenticationResult authenticationResult =
        new AuthenticationResult(
            userId, "coach@example.com", UserRole.COACH, "mock.coach.jwt", 86400L);
    when(authService.authenticate("coach@example.com", "SecurePassword#123"))
        .thenReturn(authenticationResult);

    String payload =
        """
        {
          "role": "COACH",
          "email": "coach@example.com",
          "password": "SecurePassword#123",
          "firstName": "Maya",
          "lastName": "Raman",
          "icfLevel": "PCC",
          "credentialDetails": "ICF-PCC-1029",
          "domainCodes": ["CAREER", "BURNOUT"],
          "timezone": "Asia/Kolkata",
          "biography": "Career coach"
        }
        """;

    mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.token").value("mock.coach.jwt"))
        .andExpect(jsonPath("$.user.email").value("coach@example.com"))
        .andExpect(jsonPath("$.user.role").value("COACH"));

    verify(coachService).registerCoach(any(CoachRegistrationCommand.class));
  }

  @Test
  @DisplayName("POST /api/v1/auth/register should detect coach registration via icfLevel without explicit role")
  void testRegisterCoachInferredByIcfFields() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();
    CoachProfileDetails coachProfileDetails =
        new CoachProfileDetails(
            coachId,
            userId,
            "coach2@example.com",
            "Dan",
            "Okafor",
            "Europe/London",
            "Leadership coach",
            "MCC",
            false,
            false,
            true,
            false,
            "ICF-MCC-99",
            false,
            false,
            List.of("LEADERSHIP"),
            Instant.now());

    when(coachService.registerCoach(any(CoachRegistrationCommand.class)))
        .thenReturn(coachProfileDetails);

    AuthenticationResult authenticationResult =
        new AuthenticationResult(
            userId, "coach2@example.com", UserRole.COACH, "mock.coach2.jwt", 86400L);
    when(authService.authenticate("coach2@example.com", "SecurePassword#123"))
        .thenReturn(authenticationResult);

    String payload =
        """
        {
          "email": "coach2@example.com",
          "password": "SecurePassword#123",
          "firstName": "Dan",
          "lastName": "Okafor",
          "icfMcc": true,
          "domainCodes": ["LEADERSHIP"],
          "timezone": "Europe/London"
        }
        """;

    mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.token").value("mock.coach2.jwt"))
        .andExpect(jsonPath("$.user.role").value("COACH"));
  }
}
