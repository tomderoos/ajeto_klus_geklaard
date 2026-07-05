import Foundation
import SwiftData
import UIKit

@Model
final class ChorePhoto {
    /// Legacy: bestandsnaam in Application Support/ChorePhotos. Wordt door
    /// PhotoStorage.migrateInline(...) leeg gemaakt zodra de bytes naar
    /// jpegData zijn overgezet. Blijft in het model staan voor backwards
    /// compat met bestaande installs.
    var filename: String = ""

    /// JPEG-bytes van de foto. Wordt door SwiftData+CloudKit als CKAsset in
    /// externe opslag bewaard, zodat sync tussen apparaten werkt zonder dat
    /// grote blobs het CKRecord opzwellen.
    @Attribute(.externalStorage)
    var jpegData: Data?

    var addedAt: Date = Date.now
    var chore: Chore?

    init(filename: String = "", jpegData: Data? = nil, addedAt: Date = .now) {
        self.filename = filename
        self.jpegData = jpegData
        self.addedAt = addedAt
    }

    /// Laad de foto — probeert eerst embedded jpegData, valt terug op file-based
    /// opslag voor nog-niet-gemigreerde items.
    func loadImage() -> UIImage? {
        if let data = jpegData, let image = UIImage(data: data) {
            return image
        }
        guard !filename.isEmpty else { return nil }
        return PhotoStorage.load(filename)
    }

    /// Return the current jpeg bytes — for export. Migreert lazy als nodig.
    func jpegBytes() -> Data? {
        if let data = jpegData, !data.isEmpty { return data }
        guard !filename.isEmpty, let image = PhotoStorage.load(filename) else {
            return nil
        }
        return image.jpegData(compressionQuality: 0.85)
    }
}
