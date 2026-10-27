package com.anony.api.controllers;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.anony.api.controllers.generic.ApiController;
import com.anony.api.dtos.generic.ApiErrorResponse;
import com.anony.api.dtos.generic.ApiIndexResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class ApiControllerTest {

  @Test
  @DisplayName("Should return application index metadata and documentation links")
  void testIndex() {
    ApiController controller = new ApiController();

    ApiIndexResponse apiIndexResponse = controller.index();

    assertEquals("Anony Application", apiIndexResponse.name());
    assertEquals("0.1.0", apiIndexResponse.version());
    assertEquals("/swagger-ui/index.html", apiIndexResponse.docs());
    assertEquals("/v3/api-docs", apiIndexResponse.openapi());
  }

  @Test
  @DisplayName("Should handle error with explicit status, exception, and URI path")
  void testHandleErrorWithException() {
    HttpServletRequest httpServletRequest = mock(HttpServletRequest.class);

    when(httpServletRequest.getAttribute("jakarta.servlet.error.status_code")).thenReturn(404);
    when(httpServletRequest.getAttribute("jakarta.servlet.error.exception"))
        .thenReturn(new RuntimeException("Resource not found"));
    when(httpServletRequest.getAttribute("jakarta.servlet.error.request_uri"))
        .thenReturn("/api/unknown");

    ApiController controller = new ApiController();
    ApiErrorResponse apiErrorResponse = controller.handleError(httpServletRequest);

    assertEquals(404, apiErrorResponse.status());
    assertEquals("Not Found", apiErrorResponse.error());
    assertEquals("Not Found", apiErrorResponse.message());
    assertEquals("/api/unknown", apiErrorResponse.path());
    assertNotNull(apiErrorResponse.timestamp());
  }

  @Test
  @DisplayName("Should handle error with default status, null exception, and null URI path")
  void testHandleErrorDefaults() {
    HttpServletRequest httpServletRequest = mock(HttpServletRequest.class);

    when(httpServletRequest.getAttribute("jakarta.servlet.error.status_code")).thenReturn(null);
    when(httpServletRequest.getAttribute("jakarta.servlet.error.exception")).thenReturn(null);
    when(httpServletRequest.getAttribute("jakarta.servlet.error.request_uri")).thenReturn(null);

    ApiController controller = new ApiController();
    ApiErrorResponse apiErrorResponse = controller.handleError(httpServletRequest);

    assertEquals(HttpStatus.INTERNAL_SERVER_ERROR.value(), apiErrorResponse.status());
    assertEquals("Internal Server Error", apiErrorResponse.error());
    assertEquals("Internal Server Error", apiErrorResponse.message());
    assertEquals("", apiErrorResponse.path());
    assertNotNull(apiErrorResponse.timestamp());
  }
}
