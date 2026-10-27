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
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

/** A concrete, bookable 30 or 60 minute slot generated from a coach's availability template. */
@Entity
@Table(name = "slots")
@Getter
@Setter
public class SlotEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "slot_id", nullable = false, updatable = false)
  private UUID slotId;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "availability_template_id", nullable = false)
  private AvailabilityTemplateEntity availabilityTemplate;

  @Column(name = "start_at", nullable = false)
  private Instant startAt;

  @Column(name = "end_at", nullable = false)
  private Instant endAt;

  @Column(name = "is_free_pledge", nullable = false)
  private Boolean freePledge;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;
}
