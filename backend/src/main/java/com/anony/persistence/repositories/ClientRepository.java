package com.anony.persistence.repositories;

import com.anony.persistence.entities.ClientEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link ClientEntity}. */
public interface ClientRepository extends JpaRepository<ClientEntity, UUID> {

  /**
   * Finds client entity associated with user identifier.
   *
   * @param userId user identifier
   * @return optional client entity
   */
  Optional<ClientEntity> findByUser_UserId(UUID userId);

  /**
   * Finds client entity associated with user email.
   *
   * @param email client email address
   * @return optional client entity
   */
  Optional<ClientEntity> findByUser_EmailIgnoreCase(String email);
}

