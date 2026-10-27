package com.anony.persistence.repositories;

import com.anony.persistence.entities.CoachEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link CoachEntity}. */
public interface CoachRepository extends JpaRepository<CoachEntity, UUID> {}
