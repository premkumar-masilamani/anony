package com.anony.persistence.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** Links a coach to one of the coaching domains they specialise in. */
@Entity
@Table(
    name = "coach_domains",
    uniqueConstraints = @UniqueConstraint(columnNames = {"coach_id", "domain_id"}))
@Getter
@Setter
public class CoachDomainEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "coach_domain_id", nullable = false, updatable = false)
  private UUID coachDomainId;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "coach_id", nullable = false)
  private CoachEntity coach;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "domain_id", nullable = false)
  private DomainEntity domain;
}
