import SwiftUI
import SwiftData

@main
struct AjetoApp: App {
    @UIApplicationDelegateAdaptor(AjetoAppDelegate.self) private var appDelegate

    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Chore.self, ChorePhoto.self, Room.self,
                Household.self, Person.self, Project.self
            ])
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.nl.tomderoos.Ajeto")
            )
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
            Self.performStartupTasks(container.mainContext)
        } catch {
            fatalError("Kon SwiftData-container niet aanmaken: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    @MainActor
    private static func performStartupTasks(_ context: ModelContext) {
        DedupMigration.run(context)
        let household = ensureDefaultHousehold(context)
        seedDefaultRoomsIfNeeded(context, household: household)
        backfillHousehold(context, household: household)
        PhotoStorage.migrateInline(context: context)
        HouseholdSyncEngine.shared.start(with: context)
    }

    /// Garandeer dat er altijd exact één "primair" huishouden bestaat waar
    /// nieuwe klussen/ruimtes aan gekoppeld worden. Fase 2B kan dit
    /// concept uitbreiden naar meerdere huishoudens.
    @MainActor
    private static func ensureDefaultHousehold(_ context: ModelContext) -> Household {
        var descriptor = FetchDescriptor<Household>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let household = Household()
        context.insert(household)
        try? context.save()
        return household
    }

    @MainActor
    private static func seedDefaultRoomsIfNeeded(_ context: ModelContext, household: Household) {
        // UserDefaults-vlag voorkomt dat een tweede device (na CloudKit sync)
        // opnieuw seedt terwijl er al ruimtes op weg zijn vanuit de cloud.
        // Combineert met DedupMigration voor bestaande duplicaten.
        let flagKey = "didSeedInitialRooms"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        var descriptor = FetchDescriptor<Room>()
        descriptor.fetchLimit = 1
        do {
            let existing = try context.fetch(descriptor)
            guard existing.isEmpty else {
                // Er staan al ruimtes (lokaal of net binnengekomen via sync).
                // Zet de vlag zodat we niet later alsnog per ongeluk seeden.
                UserDefaults.standard.set(true, forKey: flagKey)
                return
            }
            for (idx, seed) in RoomDefaults.seeds.enumerated() {
                let room = Room(name: seed.name, iconName: seed.iconName, sortOrder: idx)
                room.household = household
                context.insert(room)
            }
            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
        } catch {
            // Eerste keer opstarten met een lege DB — negeren.
        }
    }

    /// Bestaande klussen/ruimtes van vóór het Household-concept krijgen alsnog
    /// een link naar het default household, zodat ze automatisch mee kunnen in
    /// een toekomstige CKShare.
    @MainActor
    private static func backfillHousehold(_ context: ModelContext, household: Household) {
        var didUpdate = false

        if let chores = try? context.fetch(FetchDescriptor<Chore>()) {
            for chore in chores where chore.household == nil {
                chore.household = household
                didUpdate = true
            }
        }
        if let rooms = try? context.fetch(FetchDescriptor<Room>()) {
            for room in rooms where room.household == nil {
                room.household = household
                didUpdate = true
            }
        }
        if didUpdate {
            try? context.save()
        }
    }
}
