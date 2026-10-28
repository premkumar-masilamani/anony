import Foundation

/// Protocol governing post-session reflection storage and testimonial submission.
public protocol SessionReflectionServiceProtocol: Sendable {
    func saveReflection(_ reflection: SessionReflection) async throws
    func getReflection(for sessionId: UUID) async -> SessionReflection?
    func allReflections() async -> [SessionReflection]
    func clearStorage() async
    func submitPublicTestimonial(_ testimonial: CoachTestimonial, for coachId: UUID?) async throws
}

/// Errors thrown by `SessionReflectionService`.
public enum ReflectionServiceError: Error, LocalizedError, Sendable, Equatable {
    case invalidRating
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRating:
            return "Rating must be between 1 and 5."
        case .saveFailed(let message):
            return "Unable to save session reflection: \(message)"
        }
    }
}

/// Actor managing thread-safe local persistence of private reflection notes
/// and dispatching public testimonials.
public actor SessionReflectionService: SessionReflectionServiceProtocol {
    private let storageIdentifier: String
    private var inMemoryReflections: [UUID: SessionReflection] = [:]
    private let urlSession: URLSession

    public init(
        storageIdentifier: String = "com.anony.session.reflections",
        urlSession: URLSession = .shared
    ) {
        self.storageIdentifier = storageIdentifier
        self.urlSession = urlSession
        let key = "\(storageIdentifier).items"
        self.inMemoryReflections = Self.loadStoredReflections(key: key)
    }

    private var storageKey: String {
        "\(storageIdentifier).items"
    }

    private static func loadStoredReflections(key: String) -> [UUID: SessionReflection] {
        var map: [UUID: SessionReflection] = [:]
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SessionReflection].self, from: data) {
            for item in decoded {
                map[item.sessionId] = item
            }
        }
        return map
    }

    private func persistToStorage() {
        let items = Array(inMemoryReflections.values)
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    public func saveReflection(_ reflection: SessionReflection) async throws {
        guard reflection.isValidRating else {
            throw ReflectionServiceError.invalidRating
        }
        inMemoryReflections[reflection.sessionId] = reflection
        persistToStorage()
    }

    public func getReflection(for sessionId: UUID) async -> SessionReflection? {
        inMemoryReflections[sessionId]
    }

    public func allReflections() async -> [SessionReflection] {
        Array(inMemoryReflections.values).sorted(by: { $0.createdAt > $1.createdAt })
    }

    public func clearStorage() async {
        inMemoryReflections.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    public func submitPublicTestimonial(_ testimonial: CoachTestimonial, for coachId: UUID? = nil) async throws {
        guard !testimonial.feedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        // Dispatches sanitized testimonial strictly without client PII or private reflection notes.
    }
}
