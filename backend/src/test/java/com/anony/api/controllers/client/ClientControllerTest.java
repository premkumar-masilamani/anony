package com.anony.api.controllers.client;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.anony.domain.client.ClientProfileDetails;
import com.anony.domain.client.ClientService;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class ClientControllerTest {

  @Mock
  private ClientService clientService;

  private MockMvc mockMvc;

  @BeforeEach
  void setUp() {
    SecurityContextHolder.clearContext();
    ClientController clientController = new ClientController(clientService);
    this.mockMvc =
        MockMvcBuilders.standaloneSetup(clientController)
            .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
            .build();
  }

  @Test
  @DisplayName("GET /api/v1/clients/me should return 200 OK for authenticated client")
  void testGetClientMeSuccess() throws Exception {
    UUID userId = UUID.randomUUID();
    UUID clientId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    ClientProfileDetails clientProfileDetails =
        new ClientProfileDetails(
            clientId,
            userId,
            "client@example.com",
            "Arjun",
            "Mehta",
            "Courageous Owl",
            true,
            false,
            Instant.now());

    when(clientService.getClientProfileByUserId(userId)).thenReturn(clientProfileDetails);

    mockMvc
        .perform(
            get("/api/v1/clients/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.clientId").value(clientId.toString()))
        .andExpect(jsonPath("$.alias").value("Courageous Owl"))
        .andExpect(jsonPath("$.isAnonymous").value(true));
  }

  @Test
  @DisplayName("GET /api/v1/clients/me should return 403 Forbidden when authenticated as coach")
  void testGetClientMeForbiddenForCoach() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "coach@example.com", UserRole.COACH, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    mockMvc
        .perform(
            get("/api/v1/clients/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isForbidden());
  }

  @Test
  @DisplayName("GET /api/v1/clients/me should return 401 Unauthorized when unauthenticated")
  void testGetClientMeUnauthenticated() throws Exception {
    mockMvc
        .perform(get("/api/v1/clients/me").contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isUnauthorized());
  }

  @Test
  @DisplayName("GET /api/v1/clients/me should return 404 Not Found when client profile is missing")
  void testGetClientMeNotFound() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(clientService.getClientProfileByUserId(userId))
        .thenThrow(new IllegalStateException("Client profile not found."));

    mockMvc
        .perform(
            get("/api/v1/clients/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("Client profile not found."));
  }

  @Test
  @DisplayName("GET /api/v1/clients/me should return 400 Bad Request on invalid argument")
  void testGetClientMeIllegalArgument() throws Exception {
    UUID userId = UUID.randomUUID();
    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "client@example.com", UserRole.CLIENT, UUID.randomUUID());

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(principal, null, List.of());
    SecurityContextHolder.getContext().setAuthentication(authentication);

    when(clientService.getClientProfileByUserId(userId))
        .thenThrow(new IllegalArgumentException("Invalid client request."));

    mockMvc
        .perform(
            get("/api/v1/clients/me")
                .principal(authentication)
                .contentType(MediaType.APPLICATION_JSON))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("Invalid client request."));
  }
}
