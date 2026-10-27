package com.anony.api.controllers.generic;

import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;
import static org.springframework.http.HttpStatus.valueOf;

import com.anony.api.dtos.generic.ApiErrorResponse;
import com.anony.api.dtos.generic.ApiIndexResponse;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.webmvc.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller exposing root discovery metadata and generic error handler.
 */
@RestController
@Hidden
public class ApiController implements ErrorController {

  private static final Logger LOGGER = LoggerFactory.getLogger(ApiController.class);

  private static final String APPLICATION_NAME = "Anony Application";
  private static final String APPLICATION_VERSION = "0.1.0";
  private static final String DOCS_PATH = "/swagger-ui/index.html";
  private static final String OPENAPI_PATH = "/v3/api-docs";

  /**
   * Returns application metadata and documentation endpoints.
   *
   * @return API index response
   */
  @RequestMapping("/")
  public ApiIndexResponse index() {
    return new ApiIndexResponse(
        APPLICATION_NAME,
        APPLICATION_VERSION,
        DOCS_PATH,
        OPENAPI_PATH);
  }

  /**
   * Handles error requests forwarded by the container.
   *
   * @param request current HTTP servlet request
   * @return structured API error response
   */
  @RequestMapping("/error")
  public ApiErrorResponse handleError(HttpServletRequest request) {
    Integer status = (Integer) request.getAttribute("jakarta.servlet.error.status_code");
    Throwable exception = (Throwable) request.getAttribute("jakarta.servlet.error.exception");
    String path = (String) request.getAttribute("jakarta.servlet.error.request_uri");

    String exceptionMessage;
    if (exception != null) {
      exceptionMessage = exception.getMessage();
    } else {
      exceptionMessage = "None";
    }

    LOGGER.error(
        "Handling error status {} for path {}. Exception: {}",
        status,
        path,
        exceptionMessage);

    int statusCode;
    if (status != null) {
      statusCode = status;
    } else {
      statusCode = INTERNAL_SERVER_ERROR.value();
    }

    HttpStatus httpStatus = valueOf(statusCode);

    String resolvedPath;
    if (path != null) {
      resolvedPath = path;
    } else {
      resolvedPath = "";
    }

    return new ApiErrorResponse(
        httpStatus.value(),
        httpStatus.getReasonPhrase(),
        httpStatus.getReasonPhrase(),
        resolvedPath,
        Instant.now().toString());
  }
}
