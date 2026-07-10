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
    /// Opgeslagen als String voor CloudKit-compat. Gebruik `recurrence` voor typed access.
    var recurrenceRaw: String = Recurrence.none.rawValue
    /// Idem voor `size` — klein/middel/groot ingeschatte klus-grootte.
    var sizeRaw: String = ChoreSize.unset.rawValue
    /// Stabiele identifier die overleeft over app-launches en devices — nodig
    /// om lokale notificaties consistent te kunnen (her)plannen en cancelen.
    var stableID: String = UUID().uuidString

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

    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    var size: ChoreSize {
        get { ChoreSize(rawValue: sizeRaw) ?? .unset }
        set { sizeRaw = newValue.rawValue }
    }

    /// Toggle het afgevinkt-veld. Voor terugkerende klussen: bij aan-tikken
    /// wordt de klus niet klaar-gezet maar doorgeschoven naar de volgende
    /// occurrence (start + eind opnieuw, isDone blijft false).
    func toggleDone() {
        if isDone {
            isDone = false
            return
        }
        if recurrence == .none {
            isDone = true
            return
        }
        // Terugkerend + net afgevinkt: verschuif planning naar volgende cyclus.
        if let start = scheduledStart {
            scheduledStart = recurrence.nextOccurrence(after: start)
        }
        if let end = scheduledEnd {
            scheduledEnd = recurrence.nextOccurrence(after: end)
        }
        // isDone blijft false — er ontstaat vanzelf een nieuwe iteratie.
    }
}
