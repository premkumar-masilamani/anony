package com.anony.domain.security;

/**
 * Service contract for password hashing and verification.
 */
public interface PasswordService {

  /**
   * Hashes a raw password securely using BCrypt.
   *
   * @param rawPassword plain text password
   * @return hashed password string
   */
  String hashPassword(String rawPassword);

  /**
   * Verifies a raw password against a stored hash.
   *
   * @param rawPassword plain text password
   * @param hashedPassword stored BCrypt hash
   * @return true if the password matches the hash, false otherwise
   */
  boolean verifyPassword(String rawPassword, String hashedPassword);
}
