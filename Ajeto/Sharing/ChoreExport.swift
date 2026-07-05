import Foundation
import UIKit

enum ChoreExport {
    /// Verpakt één klus als bundle in een tijdelijk `.ajeto`-bestand.
    static func writeTempFile(for chore: Chore) throws -> URL {
        let name = safeFilename(chore.title.isEmpty ? "Klus" : chore.title)
        return try writeTempFile(for: [chore], filename: name)
    }

    /// Verpakt meerdere klussen als bundle. Foto's worden hercomprimeerd naar
    /// max. 1600 px langste zijde, JPEG 0.75, zodat de file deelbaar blijft.
    static func writeTempFile(for chores: [Chore], filename: String) throws -> URL {
        let snapshots = chores.map { makeSnapshot(from: $0) }
        let bundle = ChoresBundle(exportedAt: .now, chores: snapshots)
        let data = try ChoreSnapshot.encoder.encode(bundle)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension(ChoreSnapshot.fileExtension)

        try? FileManager.default.removeItem(at: url)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func makeSnapshot(from chore: Chore) -> ChoreSnapshot {
        let photos: [ChoreSnapshot.PhotoSnapshot] = chore.photos.compactMap { photo in
            guard let image = PhotoStorage.load(photo.filename),
                  let resized = downscale(image, maxDimension: 1600),
                  let data = resized.jpegData(compressionQuality: 0.75)
            else { return nil }
            return ChoreSnapshot.PhotoSnapshot(data: data, addedAt: photo.addedAt)
        }

        return ChoreSnapshot(
            title: chore.title,
            details: chore.details,
            scheduledStart: chore.scheduledStart,
            scheduledEnd: chore.scheduledEnd,
            isDone: chore.isDone,
            createdAt: chore.createdAt,
            roomName: chore.room?.name,
            roomIconName: chore.room?.iconName,
            photos: photos
        )
    }

    static func safeFilename(_ raw: String) -> String {
        let base = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = base.isEmpty ? "Klus" : base
        return cleaned
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
