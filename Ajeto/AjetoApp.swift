import SwiftUI
import SwiftData

@main
struct AjetoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Chore.self, ChorePhoto.self])
    }
}
