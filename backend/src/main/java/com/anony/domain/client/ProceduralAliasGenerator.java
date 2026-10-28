package com.anony.domain.client;

import java.security.SecureRandom;
import java.util.List;

/**
 * Generates random procedural aliases composed of serene/empowering adjectives and nature/creature
 * nouns whose vocabulary maps deterministically to client avatar glyphs.
 */
public class ProceduralAliasGenerator {

  /** Curated list of tranquil and empowering adjectives for anonymous client aliases. */
  public static final List<String> ADJECTIVES =
      List.of(
          "Courageous",
          "Tranquil",
          "Serene",
          "Gentle",
          "Calm",
          "Peaceful",
          "Silent",
          "Quiet",
          "Restful",
          "Mindful");

  /** Curated list of nature and creature nouns that map 1-to-1 to native iOS SF Symbols. */
  public static final List<String> NOUNS =
      List.of(
          "Owl",
          "Hare",
          "Tortoise",
          "Fish",
          "Fox",
          "Willow",
          "Meadow",
          "River",
          "Breeze",
          "Cloud",
          "Peak",
          "Star");

  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Generates a random procedural alias in the format {@code "<Adjective> <Noun>"} (for example,
   * {@code "Courageous Owl"}).
   *
   * @return randomly generated procedural alias
   */
  public String generateAlias() {
    String selectedAdjective = ADJECTIVES.get(SECURE_RANDOM.nextInt(ADJECTIVES.size()));
    String selectedNoun = NOUNS.get(SECURE_RANDOM.nextInt(NOUNS.size()));
    return selectedAdjective + " " + selectedNoun;
  }
}
