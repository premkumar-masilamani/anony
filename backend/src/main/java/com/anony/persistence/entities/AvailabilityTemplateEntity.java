package com.anony.persistence.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

/** A coach's single weekly availability template; its time ranges are availability windows. */
@Entity
@Table(name = "availability_templates")
@Getter
@Setter
public class AvailabilityTemplateEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "availability_template_id", nullable = false, updatable = false)
  private UUID availabilityTemplateId;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "coach_id", nullable = false, unique = true)
  private CoachEntity coach;

  @Column(name = "slot_duration_minutes", nullable = false)
  private Short slotDurationMinutes;

  @Column(name = "is_active", nullable = false)
  private Boolean active;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @UpdateTimestamp
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;
}
