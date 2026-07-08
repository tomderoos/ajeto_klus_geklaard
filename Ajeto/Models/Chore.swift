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

    var room: Room?
    var household: Household?
    var project: Project?
    var assignees: [Person]?

    // CloudKit-integratie eist dat alle relaties optioneel zijn. Cleanup van
    // achtergebleven ChorePhotos gebeurt handmatig in ChoreListView.delete(_:)
    // omdat CloudKit ook geen .cascade delete-rule ondersteunt.
    @Relationship(deleteRule: .nullify, inverse: \ChorePhoto.chore)
    var photos: [ChorePhoto]?

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

    /// Foto's zonder nil-coalesce boilerplate op de callsite.
    var photosList: [ChorePhoto] {
        photos ?? []
    }
}
