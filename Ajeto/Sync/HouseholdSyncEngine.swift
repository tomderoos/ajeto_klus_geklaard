import Foundation
import CloudKit
import SwiftData
import Combine
import UIKit

/// Wrapper rond CKSyncEngine voor de shared household-zone. Beheert push
/// (lokale Chore-wijzigingen → CloudKit) én pull (remote CKRecord ↔
/// SwiftData Chore-updates). Bewust beperkt tot Chore in deze eerste
/// slice; het patroon wordt in fase 2B-2b uitgebreid naar de andere models.
///
/// Owner vs participant: engine kiest z'n database (private vs shared) op
/// basis van of het gedeelde huishouden in de eigen private DB staat
/// (owner) of via een geaccepteerde CKShare in de shared DB (participant).
@MainActor
final class HouseholdSyncEngine: NSObject {
    static let shared = HouseholdSyncEngine()

    // MARK: - Configuratie

    private let container: CKContainer
    /// State-blob wordt in UserDefaults bewaard zodat CKSyncEngine bij een
    /// volgende launch verder gaat waar 'ie was (change tokens etc.).
    private let stateKey = "householdSyncEngineState"

    private var engine: CKSyncEngine?
    private var modelContext: ModelContext?
    private var role: Role = .owner

    private enum Role { case owner, participant }

    /// Records waarvan we weten dat we ze bij de volgende push moeten
    /// versturen. Wordt gevuld door observeChanges() bij ModelContext-save
    /// en door migrateExistingRecords() bij eerste share.
    private var pendingRecordIDs: Set<String> = []

    private var contextSaveObserver: NSObjectProtocol?
    private var shareAcceptedObserver: NSObjectProtocol?

    private override init() {
        container = CKContainer(identifier: HouseholdSharingService.containerIdentifier)
        super.init()
    }

    // MARK: - Public API

    /// Roept AjetoApp aan zodra ModelContainer klaar staat. Bouwt de engine,
    /// laadt bewaarde state, en start observatie.
    func start(with context: ModelContext) {
        guard engine == nil else { return }
        modelContext = context

        role = detectRole()
        let database = role == .owner
            ? container.privateCloudDatabase
            : container.sharedCloudDatabase

        var config = CKSyncEngine.Configuration(
            database: database,
            stateSerialization: loadState(),
            delegate: self
        )
        config.automaticallySync = true
        engine = CKSyncEngine(config)

        observeChanges()
    }

    /// Zet alle bestaande Chore-records op de push-queue (voor gebruik na
    /// het aanmaken van de share zodat je huidige klussen ook zichtbaar
    /// worden voor huisgenoten).
    func migrateExistingRecords() {
        guard let context = modelContext else { return }
        let allChores = (try? context.fetch(FetchDescriptor<Chore>())) ?? []
        for chore in allChores {
            pendingRecordIDs.insert(chore.stableID)
        }
        scheduleSend()
    }

    /// Force een sync-poging. Handig na een share-acceptatie.
    func requestSync() {
        Task { try? await engine?.fetchChanges() }
    }

    // MARK: - Change observation

    private func observeChanges() {
        contextSaveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.enqueueDirtyChores()
        }

        shareAcceptedObserver = NotificationCenter.default.addObserver(
            forName: .ajetoShareAccepted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.requestSync()
        }
    }

    /// Simpele change tracking voor MVP: bij elke context-save nemen we alle
    /// Chores mee. Werkt betrouwbaar, is minder efficiënt dan diff-tracking
    /// maar prima op de schaal van een huishouden.
    private func enqueueDirtyChores() {
        guard let context = modelContext else { return }
        let all = (try? context.fetch(FetchDescriptor<Chore>())) ?? []
        for chore in all {
            pendingRecordIDs.insert(chore.stableID)
        }
        scheduleSend()
    }

    private func scheduleSend() {
        guard let engine, !pendingRecordIDs.isEmpty else { return }
        let ids = pendingRecordIDs.map {
            CKRecord.ID(recordName: $0, zoneID: sharedZoneID)
        }
        engine.state.add(
            pendingRecordZoneChanges: ids.map { .saveRecord($0) }
        )
    }

    // MARK: - Role detection

    private func detectRole() -> Role {
        // MVP: standaard owner. Voor participanten (die de share hebben
        // geaccepteerd) leggen we later een marker aan die dit omkeert.
        return .owner
    }

    /// De zone-ID moet matchen met de zone die HouseholdSharingService
    /// aanmaakt (owner-kant). Voor participanten wordt deze bij
    /// share-acceptance vervangen door de zone uit CKShare.Metadata.
    private var sharedZoneID: CKRecordZone.ID {
        CKRecordZone.ID(
            zoneName: HouseholdSharingService.sharedZoneName,
            ownerName: CKCurrentUserDefaultName
        )
    }

    // MARK: - State persistence

    private func loadState() -> CKSyncEngine.State.Serialization? {
        guard let data = UserDefaults.standard.data(forKey: stateKey) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    private func saveState(_ state: CKSyncEngine.State.Serialization) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: stateKey)
    }
}

// MARK: - CKSyncEngineDelegate

extension HouseholdSyncEngine: CKSyncEngineDelegate {
    nonisolated func handleEvent(
        _ event: CKSyncEngine.Event,
        syncEngine: CKSyncEngine
    ) async {
        switch event {
        case .stateUpdate(let stateUpdate):
            await MainActor.run {
                self.saveState(stateUpdate.stateSerialization)
            }

        case .fetchedRecordZoneChanges(let changes):
            await MainActor.run {
                self.applyIncoming(changes.modifications.map(\.record))
                self.removeDeleted(changes.deletions.map(\.recordID))
            }

        case .sentRecordZoneChanges(let sent):
            await MainActor.run {
                for success in sent.savedRecords {
                    self.pendingRecordIDs.remove(success.recordID.recordName)
                }
                for failure in sent.failedRecordSaves {
                    // Voor MVP: fouten worden gelogd, retry via CKSyncEngine.
                    print("CKSyncEngine: save failed for \(failure.record.recordID): \(failure.error)")
                }
            }

        default:
            // Voor MVP negeren we de rest — CKSyncEngine handelt zone-
            // aanmaak, account-status en batching zelf af.
            break
        }
    }

    nonisolated func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let scope = context.options.scope
        let pendingChanges = syncEngine.state.pendingRecordZoneChanges.filter {
            scope.contains($0)
        }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pendingChanges) { recordID in
            await self.makeRecord(for: recordID)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func makeRecord(for recordID: CKRecord.ID) -> CKRecord? {
        guard let context = modelContext else { return nil }
        let all = (try? context.fetch(FetchDescriptor<Chore>())) ?? []
        guard let chore = all.first(where: { $0.stableID == recordID.recordName }) else {
            return nil
        }
        let record = CKRecord(recordType: ChoreRecordCoding.recordType, recordID: recordID)
        ChoreRecordCoding.encode(chore, into: record)
        return record
    }

    @MainActor
    private func applyIncoming(_ records: [CKRecord]) {
        guard let context = modelContext else { return }
        for record in records where record.recordType == ChoreRecordCoding.recordType {
            _ = ChoreRecordCoding.applyIncoming(record, in: context)
        }
        try? context.save()
    }

    @MainActor
    private func removeDeleted(_ ids: [CKRecord.ID]) {
        guard let context = modelContext else { return }
        let all = (try? context.fetch(FetchDescriptor<Chore>())) ?? []
        for id in ids {
            if let chore = all.first(where: { $0.stableID == id.recordName }) {
                context.delete(chore)
            }
        }
        try? context.save()
    }
}
