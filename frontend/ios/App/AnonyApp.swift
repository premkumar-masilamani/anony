import SwiftUI
import AnonyCore

@main
struct AnonyApp: App {
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["ANONY_API_BASE_URL"] == nil {
            APIConfig.currentBaseURL = URL(string: "http://localhost:8080")!
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
