package com.anony.persistence.entities;

import com.anony.persistence.enums.Gender;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
 * Public coach profile, including ICF credentials.
 *
 * <p>The {@code user_role} column is a database-managed constant ({@code COACH}) that, through a
 * composite foreign key, guarantees the linked user has the coach role; it is intentionally not
 * mapped here.
 */
@Entity
@Table(name = "coaches")
@Getter
@Setter
public class CoachEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @Column(name = "coach_id", nullable = false, updatable = false)
  private UUID coachId;

  @OneToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "user_id", nullable = false, unique = true)
  private UserEntity user;

  @Column(name = "first_name", nullable = false, length = 100)
  private String firstName;

  @Column(name = "last_name", nullable = false, length = 100)
  private String lastName;

  @Column(name = "photo_url", length = 2048)
  private String photoUrl;

  @Enumerated(EnumType.STRING)
  @Column(name = "gender", length = 20)
  private Gender gender;

  @Column(name = "country_code", length = 2)
  private String countryCode;

  @Column(name = "timezone", nullable = false, length = 64)
  private String timezone;

  @Column(name = "biography", length = 1000)
  private String biography;

  @Column(name = "icf_acc", nullable = false)
  private Boolean icfAcc;

  @Column(name = "icf_pcc", nullable = false)
  private Boolean icfPcc;

  @Column(name = "icf_mcc", nullable = false)
  private Boolean icfMcc;

  @Column(name = "icf_actc", nullable = false)
  private Boolean icfActc;

  @Column(name = "credential_details", length = 1000)
  private String credentialDetails;

  @Column(name = "is_verified", nullable = false)
  private Boolean verified;

  @Column(name = "is_onboarded", nullable = false)
  private Boolean onboarded;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @UpdateTimestamp
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;
}
