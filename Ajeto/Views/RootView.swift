import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ChoreListView()
                .tabItem { Label("Klussen", systemImage: "hammer") }
            PlanningView()
                .tabItem { Label("Planning", systemImage: "calendar") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Chore.self, ChorePhoto.self], inMemory: true)
}
