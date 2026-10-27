package com.anony.persistence.repositories;

import com.anony.persistence.entities.UserEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link UserEntity}. */
public interface UserRepository extends JpaRepository<UserEntity, UUID> {

  /**
   * Find a user by their email address, ignoring case.
   *
   * @param email user email address
   * @return optional user entity
   */
  Optional<UserEntity> findByEmailIgnoreCase(String email);

  /**
   * Find a user by their currently active token ID.
   *
   * @param tokenId active session token UUID
   * @return optional user entity
   */
  Optional<UserEntity> findByTokenId(UUID tokenId);
}
