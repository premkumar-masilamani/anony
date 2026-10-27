package com.anony.api.dtos.generic;

/**
 * Metadata response returned by the root API index endpoint.
 *
 * @param name application name
 * @param version application version
 * @param docs path to Swagger UI documentation
 * @param openapi path to OpenAPI v3 specification
 */
public record ApiIndexResponse(
    String name,
    String version,
    String docs,
    String openapi) {}
