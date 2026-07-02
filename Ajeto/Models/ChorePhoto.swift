import Foundation
import SwiftData

@Model
final class ChorePhoto {
    var filename: String = ""
    var addedAt: Date = Date.now
    var chore: Chore?

    init(filename: String, addedAt: Date = .now) {
        self.filename = filename
        self.addedAt = addedAt
    }
}
