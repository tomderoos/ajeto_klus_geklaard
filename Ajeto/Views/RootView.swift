import SwiftUI

struct RootView: View {
    init() {
        Self.configureAppearance()
    }

    var body: some View {
        TabView {
            ChoreListView()
                .tabItem { Label("Klussen", systemImage: "checkmark.circle") }
            PlanningView()
                .tabItem { Label("Planning", systemImage: "calendar") }
        }
        .tint(AjetoColor.ink)
    }

    private static func configureAppearance() {
        // Navigation bar
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = UIColor(AjetoColor.paper)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(AjetoColor.ink),
            .font: UIFont(name: "SpaceGrotesk-SemiBold", size: 17)
                ?? .systemFont(ofSize: 17, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AjetoColor.ink),
            .font: UIFont(name: "SpaceGrotesk-Bold", size: 34)
                ?? .systemFont(ofSize: 34, weight: .bold),
            .kern: -0.6
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        // Tab bar
        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundColor = UIColor(AjetoColor.surface)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Chore.self, ChorePhoto.self], inMemory: true)
}
