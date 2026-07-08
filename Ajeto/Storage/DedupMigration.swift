import Foundation
import SwiftData

/// Draait bij elke app-start, scene-activering en CloudKit remote-change.
/// Idempotent en agressief: dedupet Households en Rooms op naam ongeacht
/// aan welk household ze hangen. Nodig omdat multi-device seed race
/// duplicaten kan opleveren die verschillende household-refs hebben.
enum DedupMigration {
    @MainActor
    static func run(_ context: ModelContext) {
        dedupeHouseholds(context)
        dedupeRoomsGlobal(context)
    }

    @MainActor
    private static func dedupeHouseholds(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Household>(sortBy: [SortDescriptor(\.createdAt)])
        guard let households = try? context.fetch(descriptor), households.count > 1 else { return }

        let primary = households[0]
        for dup in households.dropFirst() {
            for chore in dup.chores ?? []      { chore.household = primary }
            for room in dup.rooms ?? []        { room.household = primary }
            for person in dup.persons ?? []    { person.household = primary }
            for project in dup.projects ?? []  { project.household = primary }
            context.delete(dup)
        }
        try? context.save()
    }

    /// Groepeert ALLE rooms op genormaliseerde naam (case-insensitief),
    /// ongeacht household. Kiest primary op meest-chores, tiebreak oudste
    /// createdAt. Klussen van duplicaten verhuizen mee, duplicate wordt
    /// verwijderd.
    @MainActor
    private static func dedupeRoomsGlobal(_ context: ModelContext) {
        guard let allRooms = try? context.fetch(FetchDescriptor<Room>()) else { return }

        var groups: [String: [Room]] = [:]
        for room in allRooms {
            let key = room.name.trimmingCharacters(in: .whitespaces).lowercased()
            guard !key.isEmpty else { continue }
            groups[key, default: []].append(room)
        }

        var didChange = false
        for (_, rooms) in groups where rooms.count > 1 {
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
