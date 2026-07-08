import Foundation
import UserNotifications
import SwiftData

/// Lokale notificaties voor ingeplande klussen. Werkt zonder server:
/// UNUserNotificationCenter plant lokaal, iOS delivert 15 minuten vóór
/// de starttijd. Bij edit/afvinken/verwijder herschrijven we de pending
/// notificatie op basis van `Chore.persistentModelID` (deterministisch ID).
enum NotificationService {
    /// Hoeveel minuten vóór starttijd de notificatie afgaat.
    private static let leadMinutes: Int = 15

    /// Prompt de gebruiker één keer om alert/sound-permission. Volgende
    /// aanroepen returnen de reeds bekende status. Aan te roepen vlak
    /// vóór het eerste schedule-attempt.
    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// Herschrijft de pending notificatie voor deze klus. Cancelt eerst
    /// een eventueel bestaande, plant dan opnieuw als de klus recht heeft
    /// op een notificatie (niet klaar, ingepland, in de toekomst).
    static func rescheduleNotification(for chore: Chore) {
        let id = notificationID(for: chore)
        cancel(with: id)

        guard !chore.isDone,
              let start = chore.scheduledStart
        else { return }

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -leadMinutes, to: start) ?? start
        guard triggerDate > .now else { return }

        Task {
            let granted = await requestAuthorizationIfNeeded()
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = chore.title.isEmpty ? "Klus staat op de planning" : chore.title
            content.body = subtitle(for: chore, start: start)
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    /// Cancelt de pending notificatie voor deze klus (gebruikt bij delete).
    static func cancel(for chore: Chore) {
        cancel(with: notificationID(for: chore))
    }

    // MARK: - Private helpers

    private static func cancel(with id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private static func notificationID(for chore: Chore) -> String {
        "chore-\(chore.stableID)"
    }

    private static func subtitle(for chore: Chore, start: Date) -> String {
        var parts: [String] = []
        parts.append("Start om \(start.formatted(date: .omitted, time: .shortened))")
        if let room = chore.room {
            parts.append(room.name)
        }
        return parts.joined(separator: " · ")
    }
}
