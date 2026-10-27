package com.anony.persistence.entities;

import com.anony.persistence.enums.SessionStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
import org.hibernate.annotations.UpdateTimestamp;

/**
 * A client's booking of a slot.
 *
 * <p>{@code cancelledAt} and {@code cancelledBy} are set exactly when the status is {@link
 * SessionStatus#CANCELLED}; the database allows at most one non-cancelled session per slot.
 */
@Entity
@Table(name = "sessions")
@Getter
@Setter
public class SessionEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "session_id", nullable = false, updatable = false)
  private UUID sessionId;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "slot_id", nullable = false)
  private SlotEntity slot;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "client_id", nullable = false)
  private ClientEntity client;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "domain_id")
  private DomainEntity domain;

  @Column(name = "topic", length = 500)
  private String topic;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", nullable = false, length = 20)
  private SessionStatus status;

  @Column(name = "cancelled_at")
  private Instant cancelledAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "cancelled_by")
  private UserEntity cancelledBy;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @UpdateTimestamp
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;
}
