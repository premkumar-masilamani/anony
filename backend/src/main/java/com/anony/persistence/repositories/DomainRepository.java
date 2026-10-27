package com.anony.persistence.repositories;

import com.anony.persistence.entities.DomainEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link DomainEntity}. */
public interface DomainRepository extends JpaRepository<DomainEntity, UUID> {

  /**
   * Finds domain entity by domain code ignoring case.
   *
   * @param code domain code
   * @return optional domain entity
   */
  Optional<DomainEntity> findByCodeIgnoreCase(String code);
}

