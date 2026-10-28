package com.anony.domain.session;

import java.io.Serial;

/**
 * Domain exception thrown when a client exceeds fair-use pro-bono quotas
 * (either 14-day cadence cooldown or 6-session lifetime cap).
 */
public class QuotaExceededException extends RuntimeException {

  @Serial
  private static final long serialVersionUID = 1L;

  private final String reason;
  private final int daysRemaining;
  private final int freeSessionsUsed;
  private final int maxFreeSessions;
  private final String suggestedAction;

  /**
   * Constructs quota exceeded exception with detailed enforcement metadata.
   *
   * @param message human-readable error description
   * @param reason error code reason (COOLDOWN_ACTIVE or LIFETIME_CAP_REACHED)
   * @param daysRemaining remaining days until next free session unlocks
   * @param freeSessionsUsed number of pro-bono sessions completed so far
   * @param maxFreeSessions lifetime cap of pro-bono sessions allowed
   * @param suggestedAction guidance for client to book paid sessions
   */
  public QuotaExceededException(
      String message,
      String reason,
      int daysRemaining,
      int freeSessionsUsed,
      int maxFreeSessions,
      String suggestedAction) {
    super(message);
    this.reason = reason;
    this.daysRemaining = daysRemaining;
    this.freeSessionsUsed = freeSessionsUsed;
    this.maxFreeSessions = maxFreeSessions;
    this.suggestedAction = suggestedAction;
  }

  public String getReason() {
    return reason;
  }

  public int getDaysRemaining() {
    return daysRemaining;
  }

  public int getFreeSessionsUsed() {
    return freeSessionsUsed;
  }

  public int getMaxFreeSessions() {
    return maxFreeSessions;
  }

  public String getSuggestedAction() {
    return suggestedAction;
  }
}
