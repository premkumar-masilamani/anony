package com.anony.domain.session;

import java.io.Serial;

/**
 * Domain exception thrown when a requested coaching slot is already locked or booked.
 */
public class SlotAlreadyBookedException extends RuntimeException {

  @Serial
  private static final long serialVersionUID = 1L;

  /**
   * Constructs a slot already booked exception with a descriptive message.
   *
   * @param message error description
   */
  public SlotAlreadyBookedException(String message) {
    super(message);
  }
}
