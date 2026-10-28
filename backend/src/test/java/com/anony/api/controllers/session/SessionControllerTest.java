package com.anony.api.controllers.session;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.anony.api.dtos.session.BlindMatchResponse;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.domain.session.BlindMatchCommand;
import com.anony.domain.session.BlindMatchResult;
import com.anony.domain.session.NoAvailableSlotsException;
import com.anony.domain.session.QuotaExceededException;
import com.anony.domain.session.SessionService;
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
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class SessionControllerTest {

  @Mock
  private SessionService sessionService;

  private SessionController sessionController;
  private MockMvc mockMvc;

  @BeforeEach
  void setUp() {
    SecurityContextHolder.clearContext();
    this.sessionController = new SessionController(sessionService);
    this.mockMvc =
        MockMvcBuilders.standaloneSetup(sessionController)
            .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
            .build();
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 201 Created on successful match")
  void testScheduleBlindMatchSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID sessionId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    Instant scheduledTime = Instant.parse("2026-10-28T18:00:00Z");
    Instant nextAvailableAt = Instant.parse("2026-11-11T18:00:00Z");

    BlindMatchResult matchResult =
        new BlindMatchResult(
            sessionId,
            "Coach AuraGuide",
            "PCC",
            "Overwhelmed with executive burnout",
            scheduledTime,
            "CONFIRMED",
            true,
            1,
            6,
            nextAvailableAt);

    when(sessionService.scheduleBlindMatch(any(BlindMatchCommand.class))).thenReturn(matchResult);

    String payload =
        "{\"struggle_prompt\": \"Overwhelmed with executive burnout\", \"preferred_time_window\": \"EVENING\", \"preferred_date\": \"2026-10-28\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.session_id").value(sessionId.toString()))
        .andExpect(jsonPath("$.coach_alias").value("Coach AuraGuide"))
        .andExpect(jsonPath("$.coach_icf_level").value("PCC"))
        .andExpect(jsonPath("$.status").value("CONFIRMED"))
        .andExpect(jsonPath("$.is_pro_bono").value(true))
        .andExpect(jsonPath("$.free_sessions_used").value(1))
        .andExpect(jsonPath("$.max_free_sessions").value(6));
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 409 Conflict when cooldown is active")
  void testScheduleBlindMatchCooldownActive() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(sessionService.scheduleBlindMatch(any(BlindMatchCommand.class)))
        .thenThrow(
            new QuotaExceededException(
                "You can book 1 free pro-bono session every 14 days. Your next free session unlocks in 9 days.",
                "COOLDOWN_ACTIVE",
                9,
                2,
                6,
                "SWITCH_TO_REGULAR_MODE_FOR_PAID_BOOKINGS"));

    String payload =
        "{\"struggle_prompt\": \"Need support\", \"preferred_time_window\": \"MORNING\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error").value("FREE_SESSION_QUOTA_EXCEEDED"))
        .andExpect(jsonPath("$.reason").value("COOLDOWN_ACTIVE"))
        .andExpect(jsonPath("$.days_remaining").value(9))
        .andExpect(jsonPath("$.free_sessions_used").value(2))
        .andExpect(jsonPath("$.max_free_sessions").value(6))
        .andExpect(jsonPath("$.suggested_action").value("SWITCH_TO_REGULAR_MODE_FOR_PAID_BOOKINGS"));
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 409 Conflict when lifetime cap is reached")
  void testScheduleBlindMatchLifetimeCapReached() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(sessionService.scheduleBlindMatch(any(BlindMatchCommand.class)))
        .thenThrow(
            new QuotaExceededException(
                "You have completed all 6 free pro-bono sessions. Switch to Regular Mode in your profile to browse coaches and schedule paid sessions.",
                "LIFETIME_CAP_REACHED",
                0,
                6,
                6,
                "SWITCH_TO_REGULAR_MODE_FOR_PAID_BOOKINGS"));

    String payload =
        "{\"struggle_prompt\": \"Need pro bono coaching\", \"preferred_time_window\": \"AFTERNOON\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error").value("FREE_SESSION_QUOTA_EXCEEDED"))
        .andExpect(jsonPath("$.reason").value("LIFETIME_CAP_REACHED"))
        .andExpect(jsonPath("$.days_remaining").value(0))
        .andExpect(jsonPath("$.free_sessions_used").value(6))
        .andExpect(jsonPath("$.max_free_sessions").value(6));
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 404 Not Found when no slots are available")
  void testScheduleBlindMatchNoSlotsAvailable() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(sessionService.scheduleBlindMatch(any(BlindMatchCommand.class)))
        .thenThrow(new NoAvailableSlotsException("No available pro-bono coach slots found."));

    String payload = "{\"struggle_prompt\": \"Need guidance\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("No available pro-bono coach slots found."));
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 404 Not Found when client profile missing")
  void testScheduleBlindMatchClientProfileNotFound() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(sessionService.scheduleBlindMatch(any(BlindMatchCommand.class)))
        .thenThrow(new IllegalStateException("Client profile not found."));

    String payload = "{\"struggle_prompt\": \"Need guidance\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("Client profile not found."));
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 400 Bad Request on illegal argument")
  void testScheduleBlindMatchIllegalArgument() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(sessionService.scheduleBlindMatch(any(BlindMatchCommand.class)))
        .thenThrow(new IllegalArgumentException("Invalid match prompt."));

    String payload = "{\"struggle_prompt\": \"Invalid\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("Invalid match prompt."));
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 401 Unauthorized when unauthenticated")
  void testScheduleBlindMatchUnauthenticated() throws Exception {
    String payload = "{\"struggle_prompt\": \"Need guidance\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isUnauthorized());
  }

  @Test
  @DisplayName("POST /api/v1/sessions/blind-match should return 403 Forbidden when authenticated as coach")
  void testScheduleBlindMatchForbiddenForCoach() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "coach@example.com", UserRole.COACH, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    String payload = "{\"struggle_prompt\": \"Need guidance\"}";

    mockMvc
        .perform(
            post("/api/v1/sessions/blind-match")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isForbidden());

    AuthenticatedUser clientPrincipal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());
    ResponseEntity<BlindMatchResponse> nullRequestResponse =
        sessionController.scheduleBlindMatch(clientPrincipal, null);
    assertEquals(HttpStatus.BAD_REQUEST, nullRequestResponse.getStatusCode());
  }
}
