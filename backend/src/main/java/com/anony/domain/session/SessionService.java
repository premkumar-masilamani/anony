package com.anony.domain.session;

/**
 * Service managing coaching sessions, bookings, and automated pro-bono blind matching.
 */
public interface SessionService {

  /**
   * Atomically matches and schedules an anonymous client with an available pro-bono coach slot
   * subject to 14-day cadence cooldown and 6-session lifetime cap enforcement.
   *
   * @param blindMatchCommand matching command containing client ID, struggle prompt, and time preferences
   * @return confirmed session booking result
   */
  BlindMatchResult scheduleBlindMatch(BlindMatchCommand blindMatchCommand);
}
