import Foundation

/// Hoe vaak een klus terugkomt. Opgeslagen als String (`Chore.recurrenceRaw`)
/// voor CloudKit-compat; use `Chore.recurrence` als typed getter/setter.
enum Recurrence: String, Codable, CaseIterable, Identifiable {
    case none
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:    return "Eenmalig"
        case .daily:   return "Dagelijks"
        case .weekly:  return "Wekelijks"
        case .monthly: return "Maandelijks"
        case .yearly:  return "Jaarlijks"
        }
    }

    /// Kleine label voor op klus-rows ("wekelijks", "maandelijks").
    var shortLabel: String {
        switch self {
        case .none:    return ""
        case .daily:   return "dagelijks"
        case .weekly:  return "wekelijks"
        case .monthly: return "maandelijks"
        case .yearly:  return "jaarlijks"
        }
    }

    /// Volgende datum na `date` volgens deze recurrence. Voor `.none` geeft
    /// hij de originele datum terug.
    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date {
        switch self {
        case .none:    return date
        case .daily:   return calendar.date(byAdding: .day,        value: 1, to: date) ?? date
        case .weekly:  return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly: return calendar.date(byAdding: .month,      value: 1, to: date) ?? date
        case .yearly:  return calendar.date(byAdding: .year,       value: 1, to: date) ?? date
        }
    }
}
