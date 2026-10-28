package com.anony.persistence.repositories;

import com.anony.persistence.entities.AvailabilityWindowEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link AvailabilityWindowEntity}. */
public interface AvailabilityWindowRepository
    extends JpaRepository<AvailabilityWindowEntity, UUID> {

  /**
   * Finds all weekly availability windows belonging to the given availability template.
   *
   * @param availabilityTemplateId unique availability template identifier
   * @return list of availability windows ordered by day of week and start time ascending
   */
  List<AvailabilityWindowEntity>
      findByAvailabilityTemplate_AvailabilityTemplateIdOrderByDayOfWeekAscStartTimeAsc(
          UUID availabilityTemplateId);
}
