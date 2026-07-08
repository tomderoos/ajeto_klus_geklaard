import Foundation
import SwiftData

/// Groepeert klussen + ruimtes rond één woon-omgeving. Wordt in Fase 2B via
/// CKShare gedeeld met huisgenoten; alle records die aan een Household
/// hangen krijgen die share automatisch mee.
@Model
final class Household {
    var name: String = "Mijn huishouden"
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Chore.household)
    var chores: [Chore]?

    @Relationship(deleteRule: .nullify, inverse: \Room.household)
    var rooms: [Room]?

    @Relationship(deleteRule: .nullify, inverse: \Person.household)
    var persons: [Person]?

    @Relationship(deleteRule: .nullify, inverse: \Project.household)
    var projects: [Project]?

    init(name: String = "Mijn huishouden", createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }

    /// Haalt het oudste (= primaire) huishouden op. In Fase 2A is dat er altijd
    /// precies één, aangemaakt in AjetoApp.ensureDefaultHousehold(_:).
    @MainActor
    static func primary(in context: ModelContext) -> Household? {
        var descriptor = FetchDescriptor<Household>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
