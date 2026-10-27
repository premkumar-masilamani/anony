package com.anony.persistence.repositories;

import com.anony.persistence.entities.SlotEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link SlotEntity}. */
public interface SlotRepository extends JpaRepository<SlotEntity, UUID> {}
