import Foundation
import SwiftData
import UIKit

enum ChoreImport {
    enum Error: Swift.Error {
        case unreadable
        case decodeFailed
    }

    /// Leest een `.ajeto`-bestand van schijf en levert de snapshot terug.
    /// Ondersteunt zowel gewone URLs als security-scoped file URLs (bv. uit
    /// Files-app / iMessage).
    static func readSnapshot(from url: URL) throws -> ChoreSnapshot {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            throw Error.unreadable
        }
        do {
            return try ChoreSnapshot.decoder.decode(ChoreSnapshot.self, from: data)
        } catch {
            throw Error.decodeFailed
        }
    }

    /// Zet een snapshot om in een echte Chore + ChorePhoto's in de gegeven context.
    /// Ruimte wordt gematcht op naam (case-insensitief); als 'ie niet bestaat en
    /// er zit wél een naam in de snapshot, dan wordt de ruimte automatisch
    /// aangemaakt met het meegestuurde icoon.
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
            guard let image = UIImage(data: photoData.data),
                  let filename = try? PhotoStorage.save(image, quality: 0.85)
            else { continue }
            let photo = ChorePhoto(filename: filename, addedAt: photoData.addedAt)
            context.insert(photo)
            chore.photos.append(photo)
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

        // Ruimte niet gevonden — automatisch aanmaken achter de bestaande ruimtes.
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
