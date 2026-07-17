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
    @AppStorage("userName") private var userName: String = ""
    @State private var showingOnboarding: Bool = false
    @State private var showingNameEntry: Bool = false
    /// Laatste keer dat DedupMigration draaide. Voorkomt dat een flood van
    /// CloudKit remote-change notifications de main thread blokkeert (elke
    /// migratie doet fetch + save op de main actor).
    @State private var lastDedupRun: Date = .distantPast
    private let dedupCooldown: TimeInterval = 8

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
            if phase == .active { runDedupThrottled() }
        }
        .onReceive(remoteChanges) { _ in
            runDedupThrottled()
        }
        .preferredColorScheme(.light)
        .onAppear {
            if !hasSeenOnboarding {
                showingOnboarding = true
            } else if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showingNameEntry = true
            }
        }
        .sheet(isPresented: $showingOnboarding, onDismiss: {
            hasSeenOnboarding = true
            if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showingNameEntry = true
            }
        }) {
            OnboardingView()
        }
        .sheet(isPresented: $showingNameEntry) {
            NameEntrySheet(mode: .introduction)
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

    /// Vuurt DedupMigration alleen af als 't > `dedupCooldown` geleden is dat
    /// 'ie draaide. Bij een burst CloudKit remote-change notifications
    /// (bv. wanneer een tweede device zich net na wat offline-werk sync'd)
    /// zou dat anders elke keystroke op de main thread wegvreten.
    private func runDedupThrottled() {
        let now = Date.now
        guard now.timeIntervalSince(lastDedupRun) > dedupCooldown else { return }
        lastDedupRun = now
        DedupMigration.run(context)
    }

    private static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = UIColor(AjetoColor.paper)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(AjetoColor.ink),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AjetoColor.ink),
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
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
