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

/**
 * Coaching client. When {@code anonymous} is true, coaches only ever see the {@code alias}.
 *
 * <p>The {@code user_role} column is a database-managed constant ({@code CLIENT}) that, through a
 * composite foreign key, guarantees the linked user has the client role; it is intentionally not
 * mapped here.
 */
@Entity
@Table(name = "clients")
@Getter
@Setter
public class ClientEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "client_id", nullable = false, updatable = false)
  private UUID clientId;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "user_id", nullable = false, unique = true)
  private UserEntity user;

  @Column(name = "first_name", nullable = false, length = 100)
  private String firstName;

  @Column(name = "last_name", nullable = false, length = 100)
  private String lastName;

  @Column(name = "is_anonymous", nullable = false)
  private Boolean anonymous;

  @Column(name = "alias", nullable = false, length = 64)
  private String alias;

  @Column(name = "is_onboarded", nullable = false)
  private Boolean onboarded;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @UpdateTimestamp
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;
}
