import Foundation
import SwiftData
import UIKit

enum ChoreImport {
    enum Error: Swift.Error {
        case unreadable
        case decodeFailed
    }

    /// Leest een `.ajeto`-bestand van schijf en levert altijd een ChoresBundle
    /// terug — ook als het een oude losse ChoreSnapshot (v1) is, die dan
    /// gepromoveerd wordt naar een bundle met 1 klus.
    static func readBundle(from url: URL) throws -> ChoresBundle {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            throw Error.unreadable
        }
        if let bundle = try? ChoreSnapshot.decoder.decode(ChoresBundle.self, from: data) {
            return bundle
        }
        if let legacy = try? ChoreSnapshot.decoder.decode(ChoreSnapshot.self, from: data) {
            return ChoresBundle(exportedAt: legacy.createdAt, chores: [legacy])
        }
        throw Error.decodeFailed
    }

    /// Zet alle klussen uit de bundle om naar echte Chore + ChorePhoto's in de
    /// gegeven context. Ruimtes worden gematcht op naam (case-insensitief);
    /// onbekende ruimtes worden aangemaakt met het meegestuurde icoon.
    @MainActor
    static func insert(_ bundle: ChoresBundle, into context: ModelContext) {
        for snapshot in bundle.chores {
            insert(snapshot, into: context)
        }
    }

    @MainActor
    static func insert(_ snapshot: ChoreSnapshot, into context: ModelContext) {
        let chore = Chore(
            title: snapshot.title,
            details: snapshot.details,
            scheduledStart: snapshot.scheduledStart,
            scheduledEnd: snapshot.scheduledEnd,
            isDone: snapshot.isDone,
            createdAt: .now
        )
        chore.room = resolveRoom(name: snapshot.roomName, iconName: snapshot.roomIconName, in: context)
        context.insert(chore)

        for photoData in snapshot.photos {
            let photo = ChorePhoto(jpegData: photoData.data, addedAt: photoData.addedAt)
            context.insert(photo)
            if chore.photos == nil { chore.photos = [] }
            chore.photos?.append(photo)
        }
    }

    @MainActor
    private static func resolveRoom(name: String?, iconName: String?, in context: ModelContext) -> Room? {
        guard let rawName = name?.trimmingCharacters(in: .whitespaces), !rawName.isEmpty else {
            return nil
        }
        let lowered = rawName.lowercased()

        let descriptor = FetchDescriptor<Room>()
        if let match = try? context.fetch(descriptor).first(where: { $0.name.lowercased() == lowered }) {
            return match
        }

        let allRooms = (try? context.fetch(FetchDescriptor<Room>())) ?? []
        let nextOrder = (allRooms.map(\.sortOrder).max() ?? -1) + 1
        let room = Room(
            name: rawName,
            iconName: iconName ?? "square.dashed",
            sortOrder: nextOrder
        )
        context.insert(room)
        return room
    }
}
