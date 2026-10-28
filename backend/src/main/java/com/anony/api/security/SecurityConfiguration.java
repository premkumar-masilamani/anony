package com.anony.api.security;

import jakarta.servlet.http.HttpServletResponse;
import java.util.Arrays;
import java.util.List;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * Spring Security configuration establishing stateless JWT-based authentication.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfiguration {

  private static final Logger LOGGER = LoggerFactory.getLogger(SecurityConfiguration.class);

  private final JwtAuthenticationFilter jwtAuthenticationFilter;
  private final String corsAllowedOrigins;

  /**
   * Constructs the security configuration.
   *
   * @param jwtAuthenticationFilter filter validating bearer tokens
   * @param corsAllowedOrigins comma-separated allowed origins for CORS
   */
  public SecurityConfiguration(
      JwtAuthenticationFilter jwtAuthenticationFilter,
      @Value("${anony.cors.allowed-origins}") String corsAllowedOrigins) {
    this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    this.corsAllowedOrigins = corsAllowedOrigins;
  }

  /**
   * Configures HTTP security filter chain.
   *
   * @param httpSecurity http security builder
   * @return configured security filter chain
   * @throws Exception if security configuration fails
   */
  @Bean
  public SecurityFilterChain securityFilterChain(HttpSecurity httpSecurity) throws Exception {
    LOGGER.info("Configuring stateless JWT SecurityFilterChain...");
    httpSecurity
        .cors(corsConfigurer -> corsConfigurer.configurationSource(corsConfigurationSource()))
        .csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(
            sessionConfigurer ->
                sessionConfigurer.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .exceptionHandling(
            exceptionConfigurer ->
                exceptionConfigurer.authenticationEntryPoint(
                    (request, response, authException) -> {
                      LOGGER.warn(
                          "Unauthorized request to {} {}: {}",
                          request.getMethod(),
                          request.getRequestURI(),
                          authException.getMessage());
                      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
                    }))
        .authorizeHttpRequests(
            authorizationConfigurer ->
                authorizationConfigurer
                    .requestMatchers(
                        HttpMethod.POST,
                        "/api/v1/auth/login",
                        "/api/v1/auth/register",
                        "/api/v1/coaches/register",
                        "/api/v1/coaches/login")
                    .permitAll()
                    .requestMatchers("/actuator/**")
                    .permitAll()
                    .requestMatchers(
                        "/",
                        "/error",
                        "/v3/api-docs",
                        "/v3/api-docs/**",
                        "/swagger-ui/**",
                        "/swagger-ui.html")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .addFilterBefore(
            jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

    return httpSecurity.build();
  }

  /**
   * Builds the CORS configuration source based on allowed origins.
   *
   * @return cors configuration source
   */
  @Bean
  public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();

    if (StringUtils.isNotBlank(corsAllowedOrigins)) {
      List<String> origins =
          Arrays.stream(corsAllowedOrigins.split(","))
              .map(String::trim)
              .filter(StringUtils::isNotBlank)
              .toList();
      configuration.setAllowedOrigins(origins);
      LOGGER.debug("Configured CORS allowed origins: {}", origins);
    } else {
      configuration.setAllowedOrigins(List.of());
      LOGGER.warn("No CORS allowed origins configured; defaulting to empty origin list.");
    }

    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept", "Origin"));
    configuration.setAllowCredentials(true);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
  }
}
