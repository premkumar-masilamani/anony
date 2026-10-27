package com.anony.domain.client;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.anony.domain.security.PasswordService;
import com.anony.persistence.entities.ClientEntity;
import com.anony.persistence.entities.UserEntity;
import com.anony.persistence.enums.UserRole;
import com.anony.persistence.repositories.ClientRepository;
import com.anony.persistence.repositories.UserRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DefaultClientServiceTest {

  @Mock
  private UserRepository userRepository;

  @Mock
  private ClientRepository clientRepository;

  @Mock
  private PasswordService passwordService;

  private DefaultClientService clientService;

  @BeforeEach
  void setUp() {
    clientService = new DefaultClientService(userRepository, clientRepository, passwordService);
  }

  @Test
  @DisplayName("registerClient should create client with provided names and alias")
  void testRegisterClientSuccessWithExplicitValues() {
    when(userRepository.findByEmailIgnoreCase("client@example.com")).thenReturn(Optional.empty());
    when(passwordService.hashPassword("ClientPass#123")).thenReturn("hashedPass");

    UUID userId = UUID.randomUUID();
    UserEntity savedUser = new UserEntity();
    savedUser.setUserId(userId);
    savedUser.setEmail("client@example.com");
    savedUser.setRole(UserRole.CLIENT);
    when(userRepository.save(any(UserEntity.class))).thenReturn(savedUser);

    UUID clientId = UUID.randomUUID();
    ClientEntity savedClient = new ClientEntity();
    savedClient.setClientId(clientId);
    savedClient.setUser(savedUser);
    savedClient.setFirstName("Arjun");
    savedClient.setLastName("Mehta");
    savedClient.setAlias("Courageous Owl");
    savedClient.setAnonymous(true);
    savedClient.setOnboarded(false);
    savedClient.setCreatedAt(Instant.now());
    when(clientRepository.save(any(ClientEntity.class))).thenReturn(savedClient);

    ClientRegistrationCommand command =
        new ClientRegistrationCommand(
            "client@example.com", "ClientPass#123", "Arjun", "Mehta", "Courageous Owl");

    ClientProfileDetails details = clientService.registerClient(command);


    assertNotNull(details);
    assertEquals(clientId, details.clientId());
    assertEquals(userId, details.userId());
    assertEquals("client@example.com", details.email());
    assertEquals("Arjun", details.firstName());
    assertEquals("Mehta", details.lastName());
    assertEquals("Courageous Owl", details.alias());
    assertTrue(details.isAnonymous());
  }

  @Test
  @DisplayName("registerClient should default blank firstName, lastName, and alias")
  void testRegisterClientSuccessWithDefaults() {
    when(userRepository.findByEmailIgnoreCase("blank@example.com")).thenReturn(Optional.empty());
    when(passwordService.hashPassword(anyString())).thenReturn("hashed");

    UserEntity savedUser = new UserEntity();
    savedUser.setUserId(UUID.randomUUID());
    savedUser.setEmail("blank@example.com");
    savedUser.setRole(UserRole.CLIENT);
    when(userRepository.save(any(UserEntity.class))).thenReturn(savedUser);

    ClientEntity savedClient = new ClientEntity();
    savedClient.setClientId(UUID.randomUUID());
    savedClient.setUser(savedUser);
    savedClient.setFirstName("Anonymous");
    savedClient.setLastName("Client");
    savedClient.setAlias("Courageous Client");
    savedClient.setAnonymous(true);
    savedClient.setOnboarded(false);
    savedClient.setCreatedAt(Instant.now());
    when(clientRepository.save(any(ClientEntity.class))).thenReturn(savedClient);

    ClientRegistrationCommand command =
        new ClientRegistrationCommand("blank@example.com", "ClientPass#123", "  ", "", null);

    ClientProfileDetails details = clientService.registerClient(command);

    assertNotNull(details);
    assertEquals("Anonymous", details.firstName());
    assertEquals("Client", details.lastName());
    assertEquals("Courageous Client", details.alias());
  }

  @Test
  @DisplayName("registerClient should throw on null command, blank fields, invalid bounds, existing email")
  void testRegisterClientValidationFailures() {
    assertThrows(IllegalArgumentException.class, () -> clientService.registerClient(null));

    ClientRegistrationCommand blankEmail =
        new ClientRegistrationCommand("  ", "Pass#12345", "A", "B", "Alias");
    assertThrows(IllegalArgumentException.class, () -> clientService.registerClient(blankEmail));

    ClientRegistrationCommand blankPassword =
        new ClientRegistrationCommand("valid@example.com", "   ", "A", "B", "Alias");
    assertThrows(IllegalArgumentException.class, () -> clientService.registerClient(blankPassword));

    ClientRegistrationCommand shortPass =
        new ClientRegistrationCommand("a@b.com", "short", "A", "B", "Alias");
    assertThrows(IllegalArgumentException.class, () -> clientService.registerClient(shortPass));

    ClientRegistrationCommand longPass =
        new ClientRegistrationCommand("a@b.com", "a".repeat(33), "A", "B", "Alias");
    assertThrows(IllegalArgumentException.class, () -> clientService.registerClient(longPass));

    ClientRegistrationCommand existingEmail =
        new ClientRegistrationCommand("dup@b.com", "Pass#12345", "A", "B", "Alias");
    when(userRepository.findByEmailIgnoreCase("dup@b.com"))
        .thenReturn(Optional.of(new UserEntity()));
    assertThrows(IllegalArgumentException.class, () -> clientService.registerClient(existingEmail));
  }

  @Test
  @DisplayName("getClientProfileByUserId should return details for valid user")
  void testGetClientProfileSuccess() {
    UUID userId = UUID.randomUUID();
    UUID clientId = UUID.randomUUID();

    UserEntity userEntity = new UserEntity();
    userEntity.setUserId(userId);
    userEntity.setEmail("client@example.com");

    ClientEntity clientEntity = new ClientEntity();
    clientEntity.setClientId(clientId);
    clientEntity.setUser(userEntity);
    clientEntity.setFirstName("Arjun");
    clientEntity.setLastName("Mehta");
    clientEntity.setAlias("Courageous Owl");
    clientEntity.setAnonymous(true);
    clientEntity.setOnboarded(true);
    clientEntity.setCreatedAt(Instant.now());

    when(clientRepository.findByUser_UserId(userId)).thenReturn(Optional.of(clientEntity));

    ClientProfileDetails details = clientService.getClientProfileByUserId(userId);

    assertNotNull(details);
    assertEquals(clientId, details.clientId());
    assertEquals("Arjun", details.firstName());
    assertEquals("Courageous Owl", details.alias());
  }

  @Test
  @DisplayName("getClientProfileByUserId should throw when user id is null or client not found")
  void testGetClientProfileFailures() {
    assertThrows(IllegalArgumentException.class, () -> clientService.getClientProfileByUserId(null));

    UUID unknownUserId = UUID.randomUUID();
    when(clientRepository.findByUser_UserId(unknownUserId)).thenReturn(Optional.empty());
    assertThrows(
        IllegalStateException.class, () -> clientService.getClientProfileByUserId(unknownUserId));
  }
}
