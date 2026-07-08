import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let remoteChanges = NotificationCenter.default.publisher(
        for: .NSPersistentStoreRemoteChange
    )
    @Environment(\.modelContext) private var context
    @State private var pendingImport: PendingImport?
    @State private var importErrorMessage: String?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showingOnboarding: Bool = false

    init() {
        Self.configureAppearance()
    }

    var body: some View {
        TabView {
            ChoreListView()
                .tabItem { Label("Klussen", systemImage: "checkmark.circle") }
            ProjectsView()
                .tabItem { Label("Projecten", systemImage: "square.stack.3d.up") }
            PlanningView()
                .tabItem { Label("Planning", systemImage: "calendar") }
        }
        .tint(AjetoColor.ink)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                DedupMigration.run(context)
            }
        }
        .onReceive(remoteChanges) { _ in
            DedupMigration.run(context)
        }
        .preferredColorScheme(.light)
        .onAppear {
            if !hasSeenOnboarding {
                showingOnboarding = true
            }
        }
        .sheet(isPresented: $showingOnboarding, onDismiss: {
            hasSeenOnboarding = true
        }) {
            OnboardingView()
        }
        .onOpenURL(perform: handleIncoming)
        .sheet(item: $pendingImport) { pending in
            ImportChorePreviewView(
                bundle: pending.bundle,
                onConfirm: {
                    ChoreImport.insert(pending.bundle, into: context)
                    try? context.save()
                    pendingImport = nil
                },
                onCancel: { pendingImport = nil }
            )
        }
        .alert(
            "Kan klus niet inlezen",
            isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )
        ) {
            Button("OK") { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    private func handleIncoming(_ url: URL) {
        do {
            let bundle = try ChoreImport.readBundle(from: url)
            pendingImport = PendingImport(bundle: bundle)
        } catch {
            importErrorMessage = "Het gedeelde bestand kon niet worden ingelezen."
        }
    }

    private static func configureAppearance() {
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

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundColor = UIColor(AjetoColor.surface)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

struct PendingImport: Identifiable {
    let id = UUID()
    let bundle: ChoresBundle
}

#Preview {
    RootView()
        .modelContainer(for: [Chore.self, ChorePhoto.self, Room.self], inMemory: true)
}
