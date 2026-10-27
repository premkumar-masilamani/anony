package com.anony.persistence.repositories;

import com.anony.persistence.entities.CoachDomainEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link CoachDomainEntity}. */
public interface CoachDomainRepository extends JpaRepository<CoachDomainEntity, UUID> {

  /**
   * Finds all coach domain specializations for the specified coach identifier.
   *
   * @param coachId coach identifier
   * @return list of coach domain associations
   */
  List<CoachDomainEntity> findByCoach_CoachId(UUID coachId);
}

