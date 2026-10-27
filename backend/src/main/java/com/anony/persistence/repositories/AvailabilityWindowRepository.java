package com.anony.persistence.repositories;

import com.anony.persistence.entities.AvailabilityWindowEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link AvailabilityWindowEntity}. */
public interface AvailabilityWindowRepository extends JpaRepository<AvailabilityWindowEntity, UUID> {}
