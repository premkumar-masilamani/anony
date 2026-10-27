package com.anony.api.security;

import com.anony.domain.security.AuthenticatedUser;
import com.anony.domain.security.JwtTokenService;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.repositories.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.Collections;
import java.util.Optional;
import org.apache.commons.lang3.StringUtils;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Intercepts incoming HTTP requests to decode and validate Bearer JWT tokens against active sessions.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

  private static final String AUTHORIZATION_HEADER = "Authorization";
  private static final String BEARER_PREFIX = "Bearer ";

  private final JwtTokenService jwtTokenService;
  private final UserRepository userRepository;

  /**
   * Constructs the JWT authentication filter.
   *
   * @param jwtTokenService service for parsing and verifying tokens
   * @param userRepository repository for querying user active session state
   */
  public JwtAuthenticationFilter(
      JwtTokenService jwtTokenService, UserRepository userRepository) {
    super();
    this.jwtTokenService = jwtTokenService;
    this.userRepository = userRepository;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String authorizationHeader = request.getHeader(AUTHORIZATION_HEADER);

    if (StringUtils.isNotBlank(authorizationHeader)
        && authorizationHeader.startsWith(BEARER_PREFIX)) {
      String rawToken = authorizationHeader.substring(BEARER_PREFIX.length());

      try {
        AuthenticatedUser principal = jwtTokenService.parseAndValidateToken(rawToken);
        Optional<UserEntity> userOptional = userRepository.findById(principal.userId());

        if (userOptional.isPresent()) {
          UserEntity userEntity = userOptional.get();

          if (userEntity.getTokenId() != null
              && userEntity.getTokenId().equals(principal.tokenId())
              && userEntity.getTokenExpiresAt() != null
              && userEntity.getTokenExpiresAt().isAfter(Instant.now())) {
            UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(
                    principal,
                    null,
                    Collections.singletonList(
                        new SimpleGrantedAuthority("ROLE_" + principal.role().name())));
            authentication.setDetails(
                new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);
          } else {
            SecurityContextHolder.clearContext();
          }
        } else {
          SecurityContextHolder.clearContext();
        }
      } catch (Exception exception) {
        SecurityContextHolder.clearContext();
      }
    }

    filterChain.doFilter(request, response);
  }
}
