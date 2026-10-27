package com.anony.persistence.repositories;

import com.anony.persistence.entities.AvailabilityTemplateEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link AvailabilityTemplateEntity}. */
public interface AvailabilityTemplateRepository
    extends JpaRepository<AvailabilityTemplateEntity, UUID> {

  /**
   * Finds the availability template associated with a coach identifier.
   *
   * @param coachId unique coach identifier
   * @return optional availability template entity
   */
  Optional<AvailabilityTemplateEntity> findByCoach_CoachId(UUID coachId);
}
