import Foundation
import CloudKit
import SwiftData

/// Vertaalt tussen SwiftData's Chore model en CloudKit CKRecord voor sync
/// via de shared household-zone. Beperkt tot scalar-velden — relaties
/// (room, project, assignees) volgen in latere iteraties met eigen coding.
enum ChoreRecordCoding {
    static let recordType = "AjetoChore"

    // MARK: - Keys

    private enum Key {
        static let title           = "title"
        static let details         = "details"
        static let scheduledStart  = "scheduledStart"
        static let scheduledEnd    = "scheduledEnd"
        static let isDone          = "isDone"
        static let createdAt       = "createdAt"
        static let recurrenceRaw   = "recurrenceRaw"
        static let sizeRaw         = "sizeRaw"
    }

    // MARK: - Encode

    /// Vult een CKRecord met alle scalar-velden van een Chore. Gebruikt
    /// Chore.stableID als recordName zodat we bij opnieuw pushen hetzelfde
    /// record updaten in plaats van een duplicate maken.
    static func encode(_ chore: Chore, into record: CKRecord) {
        record[Key.title]          = chore.title as CKRecordValue
        record[Key.details]        = chore.details as CKRecordValue
        record[Key.scheduledStart] = chore.scheduledStart as CKRecordValue?
        record[Key.scheduledEnd]   = chore.scheduledEnd as CKRecordValue?
        record[Key.isDone]         = chore.isDone as CKRecordValue
        record[Key.createdAt]      = chore.createdAt as CKRecordValue
        record[Key.recurrenceRaw]  = chore.recurrenceRaw as CKRecordValue
        record[Key.sizeRaw]        = chore.sizeRaw as CKRecordValue
    }

    /// Zoekt bestaand Chore-record op stableID of maakt een nieuw aan;
    /// werkt de scalar-velden bij en retourneert de (geïnserte) instance.
    /// Household-koppeling wordt op de primaire household van deze context
    /// gezet, zodat lokale filters (per-huishouden) blijven werken.
    @MainActor
    @discardableResult
    static func applyIncoming(_ record: CKRecord, in context: ModelContext) -> Chore? {
        let stableID = record.recordID.recordName
        guard !stableID.isEmpty else { return nil }

        let existing: Chore? = {
            let all = (try? context.fetch(FetchDescriptor<Chore>())) ?? []
            return all.first { $0.stableID == stableID }
        }()

        let chore = existing ?? Chore()
        if existing == nil {
            chore.stableID = stableID
            chore.household = Household.primary(in: context)
            context.insert(chore)
        }

        chore.title          = record[Key.title]          as? String ?? chore.title
        chore.details        = record[Key.details]        as? String ?? chore.details
        chore.scheduledStart = record[Key.scheduledStart] as? Date
        chore.scheduledEnd   = record[Key.scheduledEnd]   as? Date
        chore.isDone         = record[Key.isDone]         as? Bool ?? chore.isDone
        chore.createdAt      = record[Key.createdAt]      as? Date ?? chore.createdAt
        chore.recurrenceRaw  = record[Key.recurrenceRaw]  as? String ?? chore.recurrenceRaw
        chore.sizeRaw        = record[Key.sizeRaw]        as? String ?? chore.sizeRaw

        return chore
    }
}
