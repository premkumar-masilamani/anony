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

  /**
   * Finds all slots belonging to an availability template within the specified UTC time range.
   *
   * @param availabilityTemplateId unique availability template identifier
   * @param rangeStart inclusive start timestamp in UTC
   * @param rangeEnd exclusive end timestamp in UTC
   * @return list of slots ordered by start timestamp ascending
   */
  List<SlotEntity>
      findByAvailabilityTemplate_AvailabilityTemplateIdAndStartAtGreaterThanEqualAndStartAtLessThanOrderByStartAtAsc(
          UUID availabilityTemplateId, Instant rangeStart, Instant rangeEnd);

  /**
   * Finds unbooked slots for a specific coach within the requested UTC time window.
   *
   * @param coachId unique coach identifier
   * @param windowStart inclusive start timestamp in UTC
   * @param windowEnd inclusive end timestamp in UTC
   * @return list of unbooked slots ordered by start timestamp ascending
   */
  @Query(
      """
      SELECT slotEntity FROM SlotEntity slotEntity
      WHERE slotEntity.availabilityTemplate.coach.coachId = :coachId
        AND slotEntity.availabilityTemplate.active = true
        AND slotEntity.startAt >= :windowStart
        AND slotEntity.startAt <= :windowEnd
        AND NOT EXISTS (
          SELECT sessionEntity FROM SessionEntity sessionEntity
          WHERE sessionEntity.slot = slotEntity
            AND sessionEntity.status <> com.anony.persistence.enums.SessionStatus.CANCELLED
        )
      ORDER BY slotEntity.startAt ASC
      """)
  List<SlotEntity> findAvailableSlotsByCoachInWindow(
      @Param("coachId") UUID coachId,
      @Param("windowStart") Instant windowStart,
      @Param("windowEnd") Instant windowEnd);
}
