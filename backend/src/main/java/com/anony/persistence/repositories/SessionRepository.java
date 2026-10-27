package com.anony.persistence.repositories;

import com.anony.persistence.entities.SessionEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link SessionEntity}. */
public interface SessionRepository extends JpaRepository<SessionEntity, UUID> {}
