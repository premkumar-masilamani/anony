package com.anony.persistence.repositories;

import com.anony.persistence.entities.AvailabilityTemplateEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link AvailabilityTemplateEntity}. */
public interface AvailabilityTemplateRepository extends JpaRepository<AvailabilityTemplateEntity, UUID> {}
