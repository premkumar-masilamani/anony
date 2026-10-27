package com.anony.api.dtos.generic;

/**
 * Standard error response structure returned by generic error dispatching endpoints.
 *
 * @param status HTTP status code
 * @param error HTTP error description
 * @param message detailed error message
 * @param path request URI path where error occurred
 * @param timestamp ISO-8601 timestamp string representing when error occurred
 */
public record ApiErrorResponse(
    int status,
    String error,
    String message,
    String path,
    String timestamp) {}
