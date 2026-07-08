import Foundation
import SwiftData

/// Groepeert klussen rond een tijdelijk doel: "Huis verkoop klaar maken",
/// "Zolder opknappen", etc. Household-scoped. Klussen kunnen aan één
/// project hangen; personen worden aan klussen toegewezen.
@Model
final class Project {
    var name: String = ""
    var details: String = ""
    var startDate: Date?
    var deadline: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date.now

    var household: Household?

    @Relationship(deleteRule: .nullify, inverse: \Chore.project)
    var chores: [Chore]?

    init(
        name: String = "",
        details: String = "",
        startDate: Date? = nil,
        deadline: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.details = details
        self.startDate = startDate
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    /// Alle unieke personen die aan minstens één klus in dit project zijn
    /// gekoppeld. Handig voor de "teamleden"-sectie in het project-detail.
    var uniqueAssignees: [Person] {
        let all = (chores ?? []).flatMap { $0.assignees ?? [] }
        var seen: Set<PersistentIdentifier> = []
        return all.filter { person in
            if seen.contains(person.persistentModelID) { return false }
            seen.insert(person.persistentModelID)
            return true
        }
    }

    var choreCount: Int { chores?.count ?? 0 }
    var completedCount: Int { chores?.filter { $0.isDone }.count ?? 0 }
}
