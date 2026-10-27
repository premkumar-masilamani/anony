package com.anony.api.interceptors;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import jakarta.servlet.RequestDispatcher;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RequestResponseLoggingInterceptorTest {

  private RequestResponseLoggingInterceptor loggingInterceptor;
  private MockHttpServletRequest request;
  private MockHttpServletResponse response;

  @BeforeEach
  void setUp() {
    loggingInterceptor = new RequestResponseLoggingInterceptor();
    request = new MockHttpServletRequest();
    response = new MockHttpServletResponse();
  }

  @Test
  @DisplayName("preHandle sets start time attribute and returns true")
  void preHandleSetsStartTimeAndReturnsTrue() {
    boolean proceed = loggingInterceptor.preHandle(request, response, new Object());

    assertTrue(proceed);
    assertNotNull(request.getAttribute("anony.request.startTime"));
  }

  @Test
  @DisplayName("afterCompletion logs info for standard request without query string")
  void afterCompletionStandardRequestWithoutQuery() {
    request.setMethod("GET");
    request.setRequestURI("/api/v1/auth/me");
    request.setAttribute("anony.request.startTime", System.currentTimeMillis() - 25);
    response.setStatus(200);

    assertDoesNotThrow(
        () -> loggingInterceptor.afterCompletion(request, response, new Object(), null));
  }

  @Test
  @DisplayName("afterCompletion skips logging if already marked as logged")
  void afterCompletionSkipsWhenAlreadyLogged() {
    request.setMethod("GET");
    request.setRequestURI("/api/v1/auth/me");
    request.setAttribute("anony.request.logged", Boolean.TRUE);

    assertDoesNotThrow(
        () -> loggingInterceptor.afterCompletion(request, response, new Object(), null));
  }

  @Test
  @DisplayName("afterCompletion logs with query string and custom unmapped status code")
  void afterCompletionWithQueryStringAndCustomStatus() {
    request.setMethod("GET");
    request.setRequestURI("/api/v1/coaches");
    request.setQueryString("domain=CAREER");
    request.setAttribute("anony.request.startTime", System.currentTimeMillis() - 15);
    response.setStatus(999);

    assertDoesNotThrow(
        () -> loggingInterceptor.afterCompletion(request, response, new Object(), null));
  }

  @Test
  @DisplayName("afterCompletion logs error when exception is provided")
  void afterCompletionWithException() {
    request.setMethod("POST");
    request.setRequestURI("/api/v1/auth/login");
    request.setAttribute("anony.request.startTime", System.currentTimeMillis() - 50);
    response.setStatus(500);
    RuntimeException exception = new RuntimeException("Database timeout");

    assertDoesNotThrow(
        () -> loggingInterceptor.afterCompletion(request, response, new Object(), exception));
  }

  @Test
  @DisplayName("afterCompletion logs error dispatch URI and handles missing start time")
  void afterCompletionWithErrorRequestUriAndMissingStartTime() {
    request.setMethod("POST");
    request.setRequestURI("/error");
    request.setAttribute(RequestDispatcher.ERROR_REQUEST_URI, "/api/v1/auth/logout");
    response.setStatus(401);

    assertDoesNotThrow(
        () -> loggingInterceptor.afterCompletion(request, response, new Object(), null));
  }
}
