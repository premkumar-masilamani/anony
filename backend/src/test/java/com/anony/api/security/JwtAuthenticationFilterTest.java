package com.anony.api.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.anony.domain.security.AuthenticatedUser;
import com.anony.domain.security.JwtTokenService;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.UserRepository;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import java.io.IOException;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {

  @Mock
  private JwtTokenService jwtTokenService;

  @Mock
  private UserRepository userRepository;

  @Mock
  private FilterChain filterChain;

  private JwtAuthenticationFilter jwtAuthenticationFilter;

  @BeforeEach
  void setUp() {
    SecurityContextHolder.clearContext();
    jwtAuthenticationFilter = new JwtAuthenticationFilter(jwtTokenService, userRepository);
  }

  @AfterEach
  void tearDown() {
    SecurityContextHolder.clearContext();
  }

  @Test
  @DisplayName("Should successfully authenticate request when valid Bearer token matches active DB session")
  void testValidBearerTokenSetsSecurityContext() throws ServletException, IOException {
    final UUID userId = UUID.randomUUID();
    final UUID tokenId = UUID.randomUUID();
    final String rawToken = "valid.jwt.token";

    final AuthenticatedUser principal =
        new AuthenticatedUser(userId, "maya.raman@example.com", UserRole.COACH, tokenId);

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setTokenId(tokenId);
    userEntity.setTokenExpiresAt(Instant.now().plusSeconds(3600));

    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer " + rawToken);
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken(rawToken)).thenReturn(principal);
    when(userRepository.findById(userId)).thenReturn(Optional.of(userEntity));

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    assertNotNull(authentication);
    assertEquals(principal, authentication.getPrincipal());
    verify(filterChain).doFilter(request, response);
  }

  @Test
  @DisplayName("Should proceed without authentication when Authorization header is missing or non-Bearer")
  void testMissingOrNonBearerHeader() throws ServletException, IOException {
    MockHttpServletRequest request = new MockHttpServletRequest();
    MockHttpServletResponse response = new MockHttpServletResponse();

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);

    MockHttpServletRequest basicRequest = new MockHttpServletRequest();
    basicRequest.addHeader("Authorization", "Basic user:pass");
    jwtAuthenticationFilter.doFilterInternal(basicRequest, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
  }

  @Test
  @DisplayName("Should not authenticate when user does not exist in database")
  void testUserNotFoundInDatabase() throws ServletException, IOException {
    UUID userId = UUID.randomUUID();
    UUID tokenId = UUID.randomUUID();
    String rawToken = "valid.jwt.token";

    AuthenticatedUser principal =
        new AuthenticatedUser(userId, "unknown@example.com", UserRole.CLIENT, tokenId);

    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer " + rawToken);
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken(rawToken)).thenReturn(principal);
    when(userRepository.findById(userId)).thenReturn(Optional.empty());

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);
  }

  @Test
  @DisplayName("Should not authenticate when token ID in database is null (session logged out)")
  void testTokenIdInDatabaseIsNull() throws ServletException, IOException {
    final UUID userId = UUID.randomUUID();
    final UUID tokenId = UUID.randomUUID();
    final String rawToken = "valid.jwt.token";

    final AuthenticatedUser principal =
        new AuthenticatedUser(userId, "maya.raman@example.com", UserRole.COACH, tokenId);

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setTokenId(null);
    userEntity.setTokenExpiresAt(null);

    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer " + rawToken);
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken(rawToken)).thenReturn(principal);
    when(userRepository.findById(userId)).thenReturn(Optional.of(userEntity));

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);
  }

  @Test
  @DisplayName("Should not authenticate when token ID in database does not match JWT jti claim")
  void testTokenIdMismatch() throws ServletException, IOException {
    final UUID userId = UUID.randomUUID();
    final UUID oldTokenId = UUID.randomUUID();
    final UUID currentTokenId = UUID.randomUUID();
    final String rawToken = "valid.jwt.token";

    final AuthenticatedUser principal =
        new AuthenticatedUser(userId, "maya.raman@example.com", UserRole.COACH, oldTokenId);

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setTokenId(currentTokenId);
    userEntity.setTokenExpiresAt(Instant.now().plusSeconds(3600));

    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer " + rawToken);
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken(rawToken)).thenReturn(principal);
    when(userRepository.findById(userId)).thenReturn(Optional.of(userEntity));

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);
  }

  @Test
  @DisplayName("Should not authenticate when token expiration timestamp in database is expired")
  void testTokenExpiredInDatabase() throws ServletException, IOException {
    final UUID userId = UUID.randomUUID();
    final UUID tokenId = UUID.randomUUID();
    final String rawToken = "valid.jwt.token";

    final AuthenticatedUser principal =
        new AuthenticatedUser(userId, "maya.raman@example.com", UserRole.COACH, tokenId);

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setTokenId(tokenId);
    userEntity.setTokenExpiresAt(Instant.now().minusSeconds(10));

    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer " + rawToken);
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken(rawToken)).thenReturn(principal);
    when(userRepository.findById(userId)).thenReturn(Optional.of(userEntity));

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);
  }

  @Test
  @DisplayName("Should not authenticate when token expiration in database is null")
  void testTokenExpiresAtInDatabaseIsNull() throws ServletException, IOException {
    final UUID userId = UUID.randomUUID();
    final UUID tokenId = UUID.randomUUID();
    final String rawToken = "valid.jwt.token";

    final AuthenticatedUser principal =
        new AuthenticatedUser(userId, "maya.raman@example.com", UserRole.COACH, tokenId);

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setTokenId(tokenId);
    userEntity.setTokenExpiresAt(null);

    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer " + rawToken);
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken(rawToken)).thenReturn(principal);
    when(userRepository.findById(userId)).thenReturn(Optional.of(userEntity));

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);
  }

  @Test
  @DisplayName("Should clear context when token parsing throws JwtException")
  void testJwtExceptionClearsContext() throws ServletException, IOException {
    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("Authorization", "Bearer invalid.token");
    MockHttpServletResponse response = new MockHttpServletResponse();

    when(jwtTokenService.parseAndValidateToken("invalid.token"))
        .thenThrow(new JwtException("Signature mismatch"));

    jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

    assertNull(SecurityContextHolder.getContext().getAuthentication());
    verify(filterChain).doFilter(request, response);
  }
}
