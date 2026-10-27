package com.anony.domain.session;

import java.io.Serial;

/**
 * Domain exception thrown when no suitable pro-bono coach slots are available for matching.
 */
public class NoAvailableSlotsException extends RuntimeException {

  @Serial
  private static final long serialVersionUID = 1L;

  /**
   * Constructs no available slots exception with descriptive error message.
   *
   * @param message error description
   */
  public NoAvailableSlotsException(String message) {
    super(message);
  }
}
