import SwiftUI
import SwiftData

@main
struct AjetoApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Chore.self, ChorePhoto.self, Room.self])
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
        seedDefaultRoomsIfNeeded(context)
        PhotoStorage.migrateInline(context: context)
    }

    @MainActor
    private static func seedDefaultRoomsIfNeeded(_ context: ModelContext) {
        var descriptor = FetchDescriptor<Room>()
        descriptor.fetchLimit = 1
        do {
            let existing = try context.fetch(descriptor)
            guard existing.isEmpty else { return }
            for (idx, seed) in RoomDefaults.seeds.enumerated() {
                context.insert(Room(name: seed.name, iconName: seed.iconName, sortOrder: idx))
            }
            try context.save()
        } catch {
            // Eerste keer opstarten met een lege DB — negeren.
        }
    }
}
