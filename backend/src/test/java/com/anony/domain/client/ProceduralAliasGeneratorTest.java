package com.anony.domain.client;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ProceduralAliasGeneratorTest {

  @Test
  @DisplayName("generateAlias should return two-word alias from curated adjectives and nouns")
  void testGenerateAliasFormatAndVocabulary() {
    ProceduralAliasGenerator generator = new ProceduralAliasGenerator();

    for (int index = 0; index < 50; index++) {
      String generatedAlias = generator.generateAlias();
      assertNotNull(generatedAlias);
      String[] parts = generatedAlias.split(" ");
      assertTrue(parts.length == 2, "Expected '<Adjective> <Noun>' format but got: " + generatedAlias);
      assertTrue(
           ProceduralAliasGenerator.ADJECTIVES.contains(parts[0]),
          "Unexpected adjective: " + parts[0]);
      assertTrue(
          ProceduralAliasGenerator.NOUNS.contains(parts[1]),
          "Unexpected noun: " + parts[1]);
    }
  }

  @Test
  @DisplayName("generateAlias should produce varied random aliases across multiple calls")
  void testGenerateAliasRandomness() {
    ProceduralAliasGenerator generator = new ProceduralAliasGenerator();
    Set<String> distinctAliases = new HashSet<>();

    for (int index = 0; index < 30; index++) {
      distinctAliases.add(generator.generateAlias());
    }

    assertFalse(distinctAliases.isEmpty());
    assertTrue(distinctAliases.size() > 1, "Expected multiple distinct procedural aliases");
  }
}
