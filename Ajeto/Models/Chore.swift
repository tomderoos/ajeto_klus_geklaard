import Foundation
import SwiftData

@Model
final class Chore {
    var title: String = ""
    var details: String = ""
    var scheduledStart: Date?
    var scheduledEnd: Date?
    var isDone: Bool = false
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \ChorePhoto.chore)
    var photos: [ChorePhoto] = []

    init(
        title: String = "",
        details: String = "",
        scheduledStart: Date? = nil,
        scheduledEnd: Date? = nil,
        isDone: Bool = false,
        createdAt: Date = .now
    ) {
        self.title = title
        self.details = details
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
