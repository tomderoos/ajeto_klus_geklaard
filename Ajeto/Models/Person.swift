import Foundation
import SwiftData

/// Iemand die klussen doet. Household-scoped: éénmaal aanmaken, dan
/// beschikbaar voor alle projecten/klussen. In fase 2B (CKShare) worden
/// personen automatisch gedeeld via het household.
@Model
final class Person {
    var name: String = ""
    /// Hex-kleur voor de avatar-cirkel. Wordt bij aanmaken willekeurig
    /// gekozen uit `Person.palette` maar mag door de gebruiker aangepast.
    var colorHex: UInt32 = 0x12CE8E
    var sortOrder: Int = 0
    var createdAt: Date = Date.now

    var household: Household?

    @Relationship(inverse: \Chore.assignees)
    var assignedChores: [Chore]?

    init(name: String = "", colorHex: UInt32 = 0x12CE8E, sortOrder: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var initials: String {
        let parts = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let letters = parts.compactMap { $0.first }.prefix(2)
        return String(letters).uppercased()
    }

    /// Kleuren-palet — bewust gedempt zodat wit-op-kleur altijd leesbaar is.
    static let palette: [UInt32] = [
        0x12CE8E, // Ajeto-groen
        0x2563FF, // Ajeto-blauw
        0xF97316, // oranje
        0xE11D48, // rood-roze
        0x8B5CF6, // paars
        0x0EA5E9, // hemelsblauw
        0x14B8A6, // teal
        0xEAB308, // amber
        0xEC4899, // roze
        0x64748B  // slate
    ]

    /// Volgende kleur uit het palet op basis van huidig aantal personen.
    static func nextColor(existingCount: Int) -> UInt32 {
        palette[existingCount % palette.count]
    }

    /// Vindt een bestaande Person met dezelfde genormaliseerde naam of maakt
    /// er één aan. Gebruikt voor de "ik"-persoon uit de onboarding: als de
    /// gebruiker op device B ook z'n naam invult, matcht die op CloudKit-
    /// synced Person i.p.v. een dubbele te maken.
    @MainActor
    static func findOrCreate(
        name: String,
        in context: ModelContext,
        household: Household?
    ) -> Person? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lowered = trimmed.lowercased()

        if let all = try? context.fetch(FetchDescriptor<Person>()),
           let existing = all.first(where: { $0.name.lowercased() == lowered }) {
            return existing
        }

        let all = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        let person = Person(
            name: trimmed,
            colorHex: Person.nextColor(existingCount: all.count),
            sortOrder: (all.map(\.sortOrder).max() ?? -1) + 1
        )
        person.household = household
        context.insert(person)
        try? context.save()
        return person
    }
}
