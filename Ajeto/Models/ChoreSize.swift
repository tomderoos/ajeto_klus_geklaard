import SwiftUI

/// De ingeschatte grootte van een klus. Opgeslagen als String (`Chore.sizeRaw`)
/// voor CloudKit-compat, exposed via `Chore.size` als typed getter/setter.
/// De drie waarden zijn ontworpen als "gewicht"-gradient in het huisstijl-
/// palet: van licht groen (klein/snel) → goud (middel) → donker groen (groot/zwaar).
enum ChoreSize: String, Codable, CaseIterable, Identifiable {
    case unset
    case small
    case medium
    case large

    var id: String { rawValue }

    /// Volle Nederlandse omschrijving voor picker en detailscherm.
    var label: String {
        switch self {
        case .unset:  return "Geen indicatie"
        case .small:  return "Klein klusje"
        case .medium: return "Middelgroot klusje"
        case .large:  return "Grote klus"
        }
    }

    /// Compacte badge-label voor klus-rijen.
    var shortLabel: String {
        switch self {
        case .unset:  return ""
        case .small:  return "Klein"
        case .medium: return "Middel"
        case .large:  return "Groot"
        }
    }

    /// Achtergrondkleur van de badge / chip.
    var badgeBackground: Color {
        switch self {
        case .unset:  return AjetoColor.surface
        case .small:  return AjetoColor.mint
        case .medium: return AjetoColor.sky
        case .large:  return AjetoColor.greenInk
        }
    }

    /// Voorgrondkleur van de badge / chip.
    var badgeForeground: Color {
        switch self {
        case .unset:  return AjetoColor.muted
        case .small:  return AjetoColor.greenInk
        case .medium: return AjetoColor.blue
        case .large:  return .white
        }
    }
}
