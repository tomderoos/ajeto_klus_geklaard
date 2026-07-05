import Foundation
import SwiftData
import UIKit

enum PhotoStorage {
    private static let directoryName = "ChorePhotos"

    static var directoryURL: URL {
        let fm = FileManager.default
        let base = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(for filename: String) -> URL {
        directoryURL.appendingPathComponent(filename)
    }

    @discardableResult
    static func save(_ image: UIImage, quality: CGFloat = 0.85) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "PhotoStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kan foto niet coderen."])
        }
        try data.write(to: url(for: filename), options: .atomic)
        return filename
    }

    static func load(_ filename: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: filename).path)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: url(for: filename))
    }

    /// Migreert bestaande file-based foto's naar embedded jpegData in het
    /// ChorePhoto-model, zodat ze via CloudKit syncen. Draait één keer bij
    /// het opstarten. Idempotent en veilig om vaker aan te roepen — items
    /// die al gemigreerd zijn worden overgeslagen.
    @MainActor
    static func migrateInline(context: ModelContext) {
        let descriptor = FetchDescriptor<ChorePhoto>()
        guard let photos = try? context.fetch(descriptor) else { return }

        var didMigrate = false
        for photo in photos {
            // Al gemigreerd? Skip.
            if let data = photo.jpegData, !data.isEmpty { continue }
            // Geen legacy-file? Kan niets meer redden.
            guard !photo.filename.isEmpty else { continue }
            guard let image = load(photo.filename),
                  let data = image.jpegData(compressionQuality: 0.85)
            else { continue }
            photo.jpegData = data
            delete(photo.filename)
            photo.filename = ""
            didMigrate = true
        }
        if didMigrate {
            try? context.save()
        }
    }
}
