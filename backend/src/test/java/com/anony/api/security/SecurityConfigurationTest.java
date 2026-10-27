package com.anony.api.security;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AuthorizeHttpRequestsConfigurer;
import org.springframework.security.config.annotation.web.configurers.CorsConfigurer;
import org.springframework.security.config.annotation.web.configurers.CsrfConfigurer;
import org.springframework.security.config.annotation.web.configurers.ExceptionHandlingConfigurer;
import org.springframework.security.config.annotation.web.configurers.SessionManagementConfigurer;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.DefaultSecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;

class SecurityConfigurationTest {

  @Test
  @DisplayName("Should create CorsConfigurationSource bean with configured origins")
  void testCorsConfigurationSource() {
    JwtAuthenticationFilter mockFilter = mock(JwtAuthenticationFilter.class);
    String allowedOrigins = "http://localhost:3000,http://localhost:5173";
    SecurityConfiguration configuration = new SecurityConfiguration(mockFilter, allowedOrigins);

    CorsConfigurationSource source = configuration.corsConfigurationSource();
    assertNotNull(source);

    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/test");
    CorsConfiguration corsConfiguration = source.getCorsConfiguration(request);
    assertNotNull(corsConfiguration);
    assertTrue(corsConfiguration.getAllowedOrigins().contains("http://localhost:3000"));
    assertTrue(corsConfiguration.getAllowedOrigins().contains("http://localhost:5173"));
  }

  @Test
  @DisplayName("Should create CorsConfigurationSource bean with empty origins when blank")
  void testCorsConfigurationSourceBlankOrigins() {
    JwtAuthenticationFilter mockFilter = mock(JwtAuthenticationFilter.class);
    SecurityConfiguration configuration = new SecurityConfiguration(mockFilter, "   ");

    CorsConfigurationSource source = configuration.corsConfigurationSource();
    assertNotNull(source);

    MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/test");
    CorsConfiguration corsConfiguration = source.getCorsConfiguration(request);
    assertNotNull(corsConfiguration);
    assertTrue(corsConfiguration.getAllowedOrigins().isEmpty());
  }

  @Test
  @DisplayName("Should successfully construct SecurityConfiguration with dependencies")
  void testSecurityConfigurationConstruction() {
    JwtAuthenticationFilter mockFilter = mock(JwtAuthenticationFilter.class);
    SecurityConfiguration configuration =
        new SecurityConfiguration(mockFilter, "http://localhost:3000");

    assertNotNull(configuration);
  }

  @Test
  @SuppressWarnings("unchecked")
  @DisplayName("Should configure HttpSecurity and trigger customizer callbacks")
  void testSecurityFilterChainConfiguration() throws Exception {
    JwtAuthenticationFilter mockFilter = mock(JwtAuthenticationFilter.class);
    SecurityConfiguration configuration =
        new SecurityConfiguration(mockFilter, "http://localhost:3000");

    HttpSecurity httpSecurity = mock(HttpSecurity.class);
    DefaultSecurityFilterChain mockChain = mock(DefaultSecurityFilterChain.class);
    when(httpSecurity.build()).thenReturn(mockChain);

    doAnswer(
            invocation -> {
              Customizer<CorsConfigurer<HttpSecurity>> customizer = invocation.getArgument(0);
              CorsConfigurer<HttpSecurity> configurer = mock(CorsConfigurer.class);
              customizer.customize(configurer);
              return httpSecurity;
            })
        .when(httpSecurity)
        .cors(any());

    when(httpSecurity.csrf(any())).thenReturn(httpSecurity);

    doAnswer(
            invocation -> {
              Customizer<SessionManagementConfigurer<HttpSecurity>> customizer =
                  invocation.getArgument(0);
              SessionManagementConfigurer<HttpSecurity> configurer =
                  mock(SessionManagementConfigurer.class);
              customizer.customize(configurer);
              return httpSecurity;
            })
        .when(httpSecurity)
        .sessionManagement(any());

    doAnswer(
            invocation -> {
              Customizer<ExceptionHandlingConfigurer<HttpSecurity>> customizer =
                  invocation.getArgument(0);
              ExceptionHandlingConfigurer<HttpSecurity> configurer =
                  mock(ExceptionHandlingConfigurer.class);

              doAnswer(
                      entryPointInvocation -> {
                        AuthenticationEntryPoint entryPoint =
                            entryPointInvocation.getArgument(0);
                        MockHttpServletRequest mockRequest = new MockHttpServletRequest();
                        MockHttpServletResponse mockResponse = new MockHttpServletResponse();
                        entryPoint.commence(
                            mockRequest, mockResponse, mock(AuthenticationException.class));
                        return configurer;
                      })
                  .when(configurer)
                  .authenticationEntryPoint(any());

              customizer.customize(configurer);
              return httpSecurity;
            })
        .when(httpSecurity)
        .exceptionHandling(any());

    doAnswer(
            invocation -> {
              final Customizer<
                      AuthorizeHttpRequestsConfigurer<HttpSecurity>
                          .AuthorizationManagerRequestMatcherRegistry>
                  customizer = invocation.getArgument(0);
              AuthorizeHttpRequestsConfigurer<HttpSecurity>
                      .AuthorizationManagerRequestMatcherRegistry
                  registry =
                      mock(
                          AuthorizeHttpRequestsConfigurer.AuthorizationManagerRequestMatcherRegistry
                              .class);

              AuthorizeHttpRequestsConfigurer<HttpSecurity>.AuthorizedUrl authorizedUrl =
                  mock(AuthorizeHttpRequestsConfigurer.AuthorizedUrl.class);

              when(registry.requestMatchers(any(HttpMethod.class), any(String.class)))
                  .thenReturn(authorizedUrl);
              when(registry.requestMatchers(any(String.class))).thenReturn(authorizedUrl);
              when(registry.anyRequest()).thenReturn(authorizedUrl);
              when(authorizedUrl.permitAll()).thenReturn(registry);
              when(authorizedUrl.authenticated()).thenReturn(registry);

              customizer.customize(registry);
              return httpSecurity;
            })
        .when(httpSecurity)
        .authorizeHttpRequests(any());

    when(httpSecurity.addFilterBefore(any(), any())).thenReturn(httpSecurity);

    org.springframework.security.web.SecurityFilterChain result =
        configuration.securityFilterChain(httpSecurity);

    assertNotNull(result);
    verify(httpSecurity).build();
  }
}
