package com.anony.persistence.repositories;

import com.anony.persistence.entities.CoachEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link CoachEntity}. */
public interface CoachRepository extends JpaRepository<CoachEntity, UUID> {

  /**
   * Finds coach entity associated with user identifier.
   *
   * @param userId user identifier
   * @return optional coach entity
   */
  Optional<CoachEntity> findByUser_UserId(UUID userId);

  /**
   * Finds coach entity associated with user email.
   *
   * @param email coach email address
   * @return optional coach entity
   */
  Optional<CoachEntity> findByUser_EmailIgnoreCase(String email);
}

