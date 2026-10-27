package com.anony.persistence.repositories;

import com.anony.persistence.entities.ClientEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data repository for {@link ClientEntity}. */
public interface ClientRepository extends JpaRepository<ClientEntity, UUID> {}
