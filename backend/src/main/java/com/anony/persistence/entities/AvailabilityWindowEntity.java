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
import java.time.LocalTime;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/**
 * A weekly time range within an availability template.
 *
 * <p>{@code dayOfWeek} uses ISO-8601 numbering (1 = Monday ... 7 = Sunday); the times are
 * wall-clock times in the coach's timezone.
 */
@Entity
@Table(name = "availability_windows")
@Getter
@Setter
public class AvailabilityWindowEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "availability_window_id", nullable = false, updatable = false)
  private UUID availabilityWindowId;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "availability_template_id", nullable = false)
  private AvailabilityTemplateEntity availabilityTemplate;

  @Column(name = "day_of_week", nullable = false)
  private Short dayOfWeek;

  @Column(name = "start_time", nullable = false)
  private LocalTime startTime;

  @Column(name = "end_time", nullable = false)
  private LocalTime endTime;
}
