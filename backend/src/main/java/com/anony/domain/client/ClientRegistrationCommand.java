package com.anony.domain.client;

/**
 * Domain command containing all information required to register a client.
 *
 * @param email client email address
 * @param password raw password
 * @param firstName client first name
 * @param lastName client last name
 * @param alias client procedural anonymous alias
 */
public record ClientRegistrationCommand(
    String email,
    String password,
    String firstName,
    String lastName,
    String alias) {}
