package com.anony.persistence.repositories;

import com.anony.persistence.entities.SlotEntity;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data repository for {@link SlotEntity}. */
public interface SlotRepository extends JpaRepository<SlotEntity, UUID> {

  /**
   * Finds available slots in the given time range that are not already booked in an active session.
   *
   * @param windowStart start of target time window
   * @param windowEnd end of target time window
   * @return list of available slots ordered by start time
   */
  @Query(
      """
      SELECT s FROM SlotEntity s
      WHERE s.startAt >= :windowStart
        AND s.startAt <= :windowEnd
        AND s.availabilityTemplate.active = true
        AND NOT EXISTS (
          SELECT sess FROM SessionEntity sess
          WHERE sess.slot = s AND sess.status <> com.anony.persistence.enums.SessionStatus.CANCELLED
        )
      ORDER BY s.startAt ASC
      """)
  List<SlotEntity> findAvailableSlotsInWindow(
      @Param("windowStart") Instant windowStart,
      @Param("windowEnd") Instant windowEnd);
}
