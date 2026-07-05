import Foundation
import UIKit

enum ChoreExport {
    /// Verpakt een klus in een tijdelijk `.ajeto`-bestand en geeft de URL terug.
    /// Foto's worden hercomprimeerd naar max. 1600 px langste zijde, JPEG 0.75.
    static func writeTempFile(for chore: Chore) throws -> URL {
        let snapshot = try makeSnapshot(from: chore)
        let data = try ChoreSnapshot.encoder.encode(snapshot)

        let name = safeFilename(chore.title)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)
            .appendingPathExtension(ChoreSnapshot.fileExtension)

        try? FileManager.default.removeItem(at: url)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func makeSnapshot(from chore: Chore) throws -> ChoreSnapshot {
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

    private static func safeFilename(_ raw: String) -> String {
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
