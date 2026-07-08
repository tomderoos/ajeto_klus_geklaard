import Foundation
import SwiftData

/// Draait bij elke app-start om dubbele records op te ruimen die kunnen
/// ontstaan doordat meerdere devices ONAFHANKELIJK seeden vóór CloudKit
/// klaar is met initiële sync. Idempotent: als er niks te dedupen valt,
/// doet 'ie niks. Wordt aangeroepen ná ensureDefaultHousehold en vóór het
/// seeden van default rooms zodat we op één schone Household + één schone
/// ruimte-set landen.
enum DedupMigration {
    @MainActor
    static func run(_ context: ModelContext) {
        dedupeHouseholds(context)
        dedupeRoomsPerHousehold(context)
    }

    /// Als er meerdere Households zijn (typisch door multi-device seed race),
    /// kies de oudste als "primaire" en verplaats alles van de rest daarheen
    /// voordat we ze verwijderen.
    @MainActor
    private static func dedupeHouseholds(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Household>(sortBy: [SortDescriptor(\.createdAt)])
        guard let households = try? context.fetch(descriptor), households.count > 1 else { return }

        let primary = households[0]
        let duplicates = households.dropFirst()

        for dup in duplicates {
            for chore in dup.chores ?? []   { chore.household   = primary }
            for room  in dup.rooms  ?? []   { room.household    = primary }
            for person in dup.persons ?? [] { person.household  = primary }
            for project in dup.projects ?? [] { project.household = primary }
            context.delete(dup)
        }
        try? context.save()
    }

    /// Ruimtes met dezelfde naam (case-insensitief) binnen hetzelfde
    /// huishouden worden samengevoegd. Klussen die aan een duplicate hingen
    /// verhuizen naar de primaire, daarna wordt de duplicate verwijderd.
    @MainActor
    private static func dedupeRoomsPerHousehold(_ context: ModelContext) {
        guard let allRooms = try? context.fetch(FetchDescriptor<Room>()) else { return }

        // Groepeer op (household.id ?? "no-household") + genormaliseerde naam.
        var groups: [String: [Room]] = [:]
        for room in allRooms {
            let householdKey = room.household.map { "\($0.persistentModelID.hashValue)" } ?? "nil"
            let nameKey = room.name.trimmingCharacters(in: .whitespaces).lowercased()
            guard !nameKey.isEmpty else { continue }
            let key = "\(householdKey)|\(nameKey)"
            groups[key, default: []].append(room)
        }

        var didChange = false
        for (_, rooms) in groups where rooms.count > 1 {
            // Kies primary: die met de meeste chores (behoudt data), tiebreak op oudste createdAt.
            let sorted = rooms.sorted { lhs, rhs in
                let lc = lhs.chores?.count ?? 0
                let rc = rhs.chores?.count ?? 0
                if lc != rc { return lc > rc }
                return lhs.createdAt < rhs.createdAt
            }
            let primary = sorted[0]
            for dup in sorted.dropFirst() {
                for chore in dup.chores ?? [] {
                    chore.room = primary
                }
                context.delete(dup)
                didChange = true
            }
        }

        if didChange {
            try? context.save()
        }
    }
}
