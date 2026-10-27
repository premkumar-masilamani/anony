package com.anony.persistence.repositories;

import com.anony.persistence.entities.UserEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link UserEntity}. */
public interface UserRepository extends JpaRepository<UserEntity, UUID> {}
