import SwiftUI
import AnonyCore

@main
struct AnonyApp: App {
    init() {
        guard let envURLString = ProcessInfo.processInfo.environment["ANONY_API_BASE_URL"],
              let envURL = URL(string: envURLString) else {
            fatalError("Missing required environment variable: ANONY_API_BASE_URL")
        }
        APIConfig.currentBaseURL = envURL
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
