package com.anony.persistence.repositories;

import com.anony.persistence.entities.SessionEntity;
import com.anony.persistence.enums.SessionStatus;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link SessionEntity}. */
public interface SessionRepository extends JpaRepository<SessionEntity, UUID> {

  /**
   * Checks whether an active session (with status other than the given excluded status)
   * already exists for the specified slot.
   *
   * @param slotId unique slot identifier
   * @param status excluded session status (typically {@code CANCELLED})
   * @return {@code true} if an active session already locks the slot
   */
  boolean existsBySlot_SlotIdAndStatusNot(UUID slotId, SessionStatus status);
}
