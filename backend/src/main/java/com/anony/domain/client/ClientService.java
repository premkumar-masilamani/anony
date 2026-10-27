package com.anony.domain.client;

import java.util.UUID;

/**
 * Service interface managing client registration and profile lookups.
 */
public interface ClientService {

  /**
   * Registers a new client profile.
   *
   * @param clientRegistrationCommand registration command with credentials and alias
   * @return newly created client profile details
   */
  ClientProfileDetails registerClient(ClientRegistrationCommand clientRegistrationCommand);

  /**
   * Retrieves current client profile details by user identifier.
   *
   * @param userId user identifier
   * @return current client profile details
   */
  ClientProfileDetails getClientProfileByUserId(UUID userId);
}
