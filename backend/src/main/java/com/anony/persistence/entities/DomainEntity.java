package com.anony.persistence.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** Coaching domain lookup entry (for example {@code CAREER} or {@code BURNOUT}). */
@Entity
@Table(name = "domains")
@Getter
@Setter
public class DomainEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "domain_id", nullable = false, updatable = false)
  private UUID domainId;

  @Column(name = "code", nullable = false, unique = true, length = 40)
  private String code;

  @Column(name = "name", nullable = false, length = 100)
  private String name;
}
