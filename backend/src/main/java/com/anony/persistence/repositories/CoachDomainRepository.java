package com.anony.persistence.repositories;

import com.anony.persistence.entities.CoachDomainEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link CoachDomainEntity}. */
public interface CoachDomainRepository extends JpaRepository<CoachDomainEntity, UUID> {}
