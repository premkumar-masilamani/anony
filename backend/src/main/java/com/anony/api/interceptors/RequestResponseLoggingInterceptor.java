package com.anony.api.interceptors;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Interceptor that logs a single line summary of each incoming HTTP request and its response.
 */
@Component
public class RequestResponseLoggingInterceptor implements HandlerInterceptor {

  private static final Logger LOGGER =
      LoggerFactory.getLogger(RequestResponseLoggingInterceptor.class);
  private static final String START_TIME_ATTRIBUTE = "anony.request.startTime";
  private static final String LOGGED_ATTRIBUTE = "anony.request.logged";

  @Override
  public boolean preHandle(
      HttpServletRequest request,
      HttpServletResponse response,
      Object handler) {
    request.setAttribute(START_TIME_ATTRIBUTE, System.currentTimeMillis());
    LOGGER.debug("Incoming HTTP {} {}", request.getMethod(), resolveRequestUri(request));
    return true;
  }

  @Override
  public void afterCompletion(
      HttpServletRequest request,
      HttpServletResponse response,
      Object handler,
      Exception exception) {
    if (request.getAttribute(LOGGED_ATTRIBUTE) == null) {
      request.setAttribute(LOGGED_ATTRIBUTE, Boolean.TRUE);

      Long startTime = (Long) request.getAttribute(START_TIME_ATTRIBUTE);
      long durationMilliseconds;
      if (startTime != null) {
        durationMilliseconds = System.currentTimeMillis() - startTime;
      } else {
        durationMilliseconds = 0L;
      }

      String requestUri = resolveRequestUri(request);
      int statusCode = response.getStatus();
      String statusDescription = resolveStatusDescription(statusCode);

      if (exception == null) {
        LOGGER.info(
            "HTTP {} {} - {} ({}ms)",
            request.getMethod(),
            requestUri,
            statusDescription,
            durationMilliseconds);
      } else {
        LOGGER.error(
            "HTTP {} {} - {} ({}ms) - Error: {}",
            request.getMethod(),
            requestUri,
            statusDescription,
            durationMilliseconds,
            exception.getMessage());
      }
    }
  }

  private String resolveRequestUri(HttpServletRequest request) {
    String originalUri = (String) request.getAttribute(RequestDispatcher.ERROR_REQUEST_URI);
    String targetUri;
    if (StringUtils.isBlank(originalUri)) {
      targetUri = request.getRequestURI();
    } else {
      targetUri = originalUri;
    }

    String queryString = request.getQueryString();
    if (StringUtils.isBlank(queryString)) {
      return targetUri;
    } else {
      return targetUri + "?" + queryString;
    }
  }

  private String resolveStatusDescription(int statusCode) {
    HttpStatus httpStatus = HttpStatus.resolve(statusCode);
    if (httpStatus != null) {
      return statusCode + " " + httpStatus.getReasonPhrase();
    } else {
      return String.valueOf(statusCode);
    }
  }
}
