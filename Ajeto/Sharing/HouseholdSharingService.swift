import Foundation
import CloudKit
import SwiftData

/// Beheer van CKShare voor het huishouden. Werkt naast de bestaande
/// SwiftData+CloudKit setup: SwiftData houdt lokale records bij in de
/// private zone; deze service maakt daarnaast een custom shared zone met
/// een CKRecord voor het huishouden waar de CKShare aan hangt. Data-
/// migratie (klussen/ruimtes verhuizen naar de shared zone) volgt in
/// Fase 2B-2.
@MainActor
final class HouseholdSharingService {
    static let shared = HouseholdSharingService()

    // MARK: - CloudKit configuratie

    static let containerIdentifier = "iCloud.nl.tomderoos.Ajeto"
    static let householdRecordType = "AjetoHousehold"
    static let sharedZoneName = "AjetoHouseholdZone"

    private let container: CKContainer
    private let privateDB: CKDatabase

    private init() {
        container = CKContainer(identifier: Self.containerIdentifier)
        privateDB = container.privateCloudDatabase
    }

    // MARK: - Public API

    /// Zorgt dat de custom shared zone bestaat, maakt/updated het
    /// huishouden-record erin, en levert een CKShare terug (bestaand of nieuw).
    /// Bij nieuwe CKShare: `publicPermission = .none` — alleen expliciet
    /// uitgenodigde deelnemers krijgen toegang.
    func prepareShare(for household: Household) async throws -> (CKShare, CKContainer) {
        let zone = try await ensureSharedZone()
        let record = try await ensureHouseholdRecord(household: household, in: zone)

        if let existingRef = record.share {
            let existingShare = try await fetchShare(with: existingRef.recordID)
            return (existingShare, container)
        }

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = household.name as CKRecordValue
        share.publicPermission = .none

        let (savedRecords, _) = try await privateDB.modifyRecords(
            saving: [record, share],
            deleting: [],
            savePolicy: .ifServerRecordUnchanged
        )
        guard case .success(let savedShare) = savedRecords[share.recordID],
              let ckShare = savedShare as? CKShare else {
            throw HouseholdSharingError.shareCreationFailed
        }
        return (ckShare, container)
    }

    /// Levert de bestaande share terug als 't huishouden gedeeld is, anders nil.
    /// Wordt gebruikt om een "Beheer huisgenoten"-scherm te tonen voor een al
    /// gedeeld huishouden.
    func existingShare(for household: Household) async -> CKShare? {
        do {
            let zone = try await ensureSharedZone()
            let record = try await ensureHouseholdRecord(household: household, in: zone)
            guard let ref = record.share else { return nil }
            return try await fetchShare(with: ref.recordID)
        } catch {
            return nil
        }
    }

    /// Accepteert een binnenkomende share invitation (bv. via URL van
    /// iMessage). Roep aan vanuit .onOpenURL / SceneDelegate.
    func acceptShareInvitation(with metadata: CKShare.Metadata) async throws {
        _ = try await container.accept(metadata)
    }

    // MARK: - Private helpers

    private func ensureSharedZone() async throws -> CKRecordZone {
        let zoneID = CKRecordZone.ID(zoneName: Self.sharedZoneName, ownerName: CKCurrentUserDefaultName)
        do {
            return try await privateDB.recordZone(for: zoneID)
        } catch {
            let zone = CKRecordZone(zoneID: zoneID)
            let (saved, _) = try await privateDB.modifyRecordZones(saving: [zone], deleting: [])
            guard case .success(let savedZone) = saved[zoneID] else {
                throw HouseholdSharingError.zoneCreationFailed
            }
            return savedZone
        }
    }

    private func ensureHouseholdRecord(
        household: Household,
        in zone: CKRecordZone
    ) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: household.stableID, zoneID: zone.zoneID)
        do {
            let existing = try await privateDB.record(for: recordID)
            existing["name"] = household.name as CKRecordValue
            let (saved, _) = try await privateDB.modifyRecords(
                saving: [existing], deleting: [], savePolicy: .allKeys
            )
            guard case .success(let updated) = saved[recordID] else {
                throw HouseholdSharingError.recordSaveFailed
            }
            return updated
        } catch let error as CKError where error.code == .unknownItem {
            let record = CKRecord(recordType: Self.householdRecordType, recordID: recordID)
            record["name"] = household.name as CKRecordValue
            let (saved, _) = try await privateDB.modifyRecords(
                saving: [record], deleting: [], savePolicy: .allKeys
            )
            guard case .success(let newRecord) = saved[recordID] else {
                throw HouseholdSharingError.recordSaveFailed
            }
            return newRecord
        }
    }

    private func fetchShare(with recordID: CKRecord.ID) async throws -> CKShare {
        let record = try await privateDB.record(for: recordID)
        guard let share = record as? CKShare else {
            throw HouseholdSharingError.shareFetchFailed
        }
        return share
    }
}

enum HouseholdSharingError: LocalizedError {
    case zoneCreationFailed
    case recordSaveFailed
    case shareCreationFailed
    case shareFetchFailed

    var errorDescription: String? {
        switch self {
        case .zoneCreationFailed:  return "Kon geen gedeelde CloudKit-zone aanmaken."
        case .recordSaveFailed:    return "Kon huishouden niet opslaan in CloudKit."
        case .shareCreationFailed: return "Kon deel-uitnodiging niet aanmaken."
        case .shareFetchFailed:    return "Kon bestaande deel-uitnodiging niet ophalen."
        }
    }
}
