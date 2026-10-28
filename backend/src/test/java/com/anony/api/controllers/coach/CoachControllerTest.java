package com.anony.api.controllers.coach;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.anony.domain.coach.CoachAvailabilitySlotDetails;
import com.anony.domain.coach.CoachProfileDetails;
import com.anony.domain.coach.CoachService;
import com.anony.domain.coach.CoachUpdateCommand;
import com.anony.domain.security.AuthenticatedUser;
import com.anony.persistence.enums.UserRole;
import java.math.BigDecimal;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class CoachControllerTest {

  @Mock
  private CoachService coachService;

  private MockMvc mockMvc;

  @BeforeEach
  void setUp() {
    SecurityContextHolder.clearContext();
    CoachController coachController = new CoachController(coachService);
    this.mockMvc =
        MockMvcBuilders.standaloneSetup(coachController)
            .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
            .build();
  }

  @Test
  @DisplayName("PUT /api/v1/coaches/me should return 400 Bad Request on service validation error")
  void testUpdateCoachValidationError() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "coach@example.com", UserRole.COACH, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(coachService.updateCoachProfile(eq(userId), any(CoachUpdateCommand.class)))
        .thenThrow(new IllegalArgumentException("At least one ICF credential is required."));

    String payload =
        """
        {
          "firstName": "Maya",
          "lastName": "Raman",
          "timezone": "Asia/Kolkata"
        }
        """;

    mockMvc
        .perform(
            put("/api/v1/coaches/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("At least one ICF credential is required."));
  }

  @Test
  @DisplayName("GET /api/v1/coaches/me should return coach profile and reflect verification state")
  void testCoachMeReflectsUpdatedVerificationStatus() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "coach@example.com", UserRole.COACH, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    CoachProfileDetails verifiedDetails =
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
            true,
            true,
            List.of("CAREER"),
            Instant.now());

    when(coachService.getCoachProfileByUserId(userId)).thenReturn(verifiedDetails);

    mockMvc
        .perform(
            get("/api/v1/coaches/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.coachId").value(coachId.toString()))
        .andExpect(jsonPath("$.isVerified").value(true));
  }

  @Test
  @DisplayName("GET /api/v1/coaches/me should return 403 Forbidden when authenticated as client")
  void testCoachMeForbiddenForClient() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    mockMvc
        .perform(
            get("/api/v1/coaches/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isForbidden());
  }

  @Test
  @DisplayName("GET /api/v1/coaches/me should return 401 Unauthorized when unauthenticated")
  void testCoachMeUnauthenticated() throws Exception {
    mockMvc
        .perform(get("/api/v1/coaches/me").contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isUnauthorized());
  }

  @Test
  @DisplayName("GET /api/v1/coaches/me should return 404 Not Found when coach record is missing")
  void testCoachMeNotFound() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "coach@example.com", UserRole.COACH, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(coachService.getCoachProfileByUserId(userId))
        .thenThrow(new IllegalStateException("Coach profile not found."));

    mockMvc
        .perform(
            get("/api/v1/coaches/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("Coach profile not found."));
  }

  @Test
  @DisplayName("PUT /api/v1/coaches/me should update coach profile and return 200 OK")
  void testUpdateProfileSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID coachId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "coach@example.com", UserRole.COACH, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    CoachProfileDetails updatedDetails =
        new CoachProfileDetails(
            coachId,
            userId,
            "coach@example.com",
            "UpdatedMaya",
            "UpdatedRaman",
            "https://photo.example.com",
            "FEMALE",
            "IN",
            "Asia/Kolkata",
            "Updated career coach bio",
            "MCC",
            false,
            false,
            true,
            false,
            "Updated credentials",
            new BigDecimal("220.00"),
            false,
            true,
            List.of("LEADERSHIP"),
            Instant.now());

    when(coachService.updateCoachProfile(eq(userId), any(CoachUpdateCommand.class)))
        .thenReturn(updatedDetails);

    String payload =
        """
        {
          "firstName": "UpdatedMaya",
          "lastName": "UpdatedRaman",
          "timezone": "Asia/Kolkata",
          "biography": "Updated career coach bio",
          "icfMcc": true,
          "credentialDetails": "Updated credentials",
          "domainCodes": ["LEADERSHIP"],
          "hourlyRate": 220.00
        }
        """;

    mockMvc
        .perform(
            put("/api/v1/coaches/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.firstName").value("UpdatedMaya"))
        .andExpect(jsonPath("$.lastName").value("UpdatedRaman"))
        .andExpect(jsonPath("$.icfMcc").value(true));
  }

  @Test
  @DisplayName("PUT /api/v1/coaches/me should return 403 Forbidden for non-coach role")
  void testUpdateProfileForbiddenForClient() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    String payload =
        """
        {
          "firstName": "Updated",
          "lastName": "Client",
          "timezone": "UTC"
        }
        """;

    mockMvc
        .perform(
            put("/api/v1/coaches/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isForbidden());
  }

  @Test
  @DisplayName("PUT /api/v1/coaches/me should return 401 Unauthorized when unauthenticated")
  void testUpdateProfileUnauthenticated() throws Exception {
    String payload =
        """
        {
          "firstName": "Updated",
          "lastName": "Name",
          "timezone": "UTC"
        }
        """;

    mockMvc
        .perform(
            put("/api/v1/coaches/me")
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
        .andExpect(status().isUnauthorized());
  }

  @Test
  @DisplayName("GET /api/v1/coaches/{id}/availabilities should return unbooked slots filtered by UTC date range")
  void testGetCoachAvailabilities() throws Exception {
    UUID coachId = UUID.randomUUID();
    UUID slotId = UUID.randomUUID();
    Instant from = Instant.parse("2027-05-01T00:00:00Z");
    Instant to = Instant.parse("2027-05-31T23:59:59Z");
    Instant slotStart = Instant.parse("2027-05-10T14:00:00Z");
    Instant slotEnd = Instant.parse("2027-05-10T15:00:00Z");

    CoachAvailabilitySlotDetails slotDetails =
        new CoachAvailabilitySlotDetails(slotId, coachId, slotStart, slotEnd, 60, true, false);
    when(coachService.getCoachAvailabilities(coachId, from, to)).thenReturn(List.of(slotDetails));

    mockMvc
        .perform(
            get("/api/v1/coaches/" + coachId + "/availabilities")
                .param("from", "2027-05-01T00:00:00Z")
                .param("to", "2027-05-31T23:59:59Z")
                .accept(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].slotId").value(slotId.toString()))
        .andExpect(jsonPath("$[0].coachId").value(coachId.toString()))
        .andExpect(jsonPath("$[0].durationMinutes").value(60))
        .andExpect(jsonPath("$[0].isFreePledge").value(true))
        .andExpect(jsonPath("$[0].isBooked").value(false));
  }
}
