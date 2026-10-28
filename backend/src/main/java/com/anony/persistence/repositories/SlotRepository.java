package com.anony.persistence.repositories;

import com.anony.persistence.entities.SlotEntity;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data repository for {@link SlotEntity}. */
public interface SlotRepository extends JpaRepository<SlotEntity, UUID> {

  /**
   * Acquires a pessimistic write lock on a specific slot by its unique identifier.
   *
   * @param slotId unique slot identifier
   * @return optional locked slot entity
   */
  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("SELECT slotEntity FROM SlotEntity slotEntity WHERE slotEntity.slotId = :slotId")
  Optional<SlotEntity> findByIdWithLock(@Param("slotId") UUID slotId);

  /**
   * Finds and locks available free-pledge slots matching a specific coaching domain code
   * within the given UTC time range.
   *
   * @param domainCode coaching domain code filter
   * @param windowStart start of target time window
   * @param windowEnd end of target time window
   * @return list of available locked slots ordered by start time
   */
  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query(
      """
      SELECT slotEntity FROM SlotEntity slotEntity
      WHERE slotEntity.startAt >= :windowStart
        AND slotEntity.startAt <= :windowEnd
        AND slotEntity.freePledge = true
        AND slotEntity.availabilityTemplate.active = true
        AND EXISTS (
          SELECT coachDomainEntity FROM CoachDomainEntity coachDomainEntity
          WHERE coachDomainEntity.coach = slotEntity.availabilityTemplate.coach
            AND UPPER(coachDomainEntity.domain.code) = UPPER(:domainCode)
        )
        AND NOT EXISTS (
          SELECT sessionEntity FROM SessionEntity sessionEntity
          WHERE sessionEntity.slot = slotEntity
            AND sessionEntity.status <> com.anony.persistence.enums.SessionStatus.CANCELLED
        )
      ORDER BY slotEntity.startAt ASC
      """)
  List<SlotEntity> findAvailableFreeSlotsByDomainInWindow(
      @Param("domainCode") String domainCode,
      @Param("windowStart") Instant windowStart,
      @Param("windowEnd") Instant windowEnd);

  /**
   * Finds and locks available free-pledge slots in the given time range that are not already booked
   * in an active session.
   *
   * @param windowStart start of target time window
   * @param windowEnd end of target time window
   * @return list of available slots ordered by start time
   */
  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query(
      """
      SELECT slotEntity FROM SlotEntity slotEntity
      WHERE slotEntity.startAt >= :windowStart
        AND slotEntity.startAt <= :windowEnd
        AND slotEntity.freePledge = true
        AND slotEntity.availabilityTemplate.active = true
        AND NOT EXISTS (
          SELECT sessionEntity FROM SessionEntity sessionEntity
          WHERE sessionEntity.slot = slotEntity
            AND sessionEntity.status <> com.anony.persistence.enums.SessionStatus.CANCELLED
        )
      ORDER BY slotEntity.startAt ASC
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
