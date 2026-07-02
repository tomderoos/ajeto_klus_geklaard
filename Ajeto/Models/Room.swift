import Foundation
import SwiftData

@Model
final class Room {
    var name: String = ""
    var iconName: String = "square.dashed"
    var sortOrder: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Chore.room)
    var chores: [Chore] = []

    init(name: String, iconName: String, sortOrder: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

enum RoomDefaults {
    struct Seed {
        let name: String
        let iconName: String
    }

    static let seeds: [Seed] = [
        Seed(name: "Woonkamer",  iconName: "sofa.fill"),
        Seed(name: "Keuken",     iconName: "fork.knife"),
        Seed(name: "Slaapkamer", iconName: "bed.double.fill"),
        Seed(name: "Badkamer",   iconName: "shower.fill"),
        Seed(name: "Tuin",       iconName: "leaf.fill"),
        Seed(name: "WC",         iconName: "toilet.fill")
    ]

    /// Beschikbare iconen voor de picker.
    static let availableIcons: [String] = [
        "sofa.fill", "fork.knife", "bed.double.fill", "shower.fill",
        "toilet.fill", "leaf.fill", "tree.fill", "car.fill",
        "stairs", "washer.fill", "lamp.desk.fill", "books.vertical.fill",
        "gamecontroller.fill", "tv.fill", "figure.and.child.holdinghands",
        "wrench.and.screwdriver.fill", "paintbrush.fill", "hammer.fill",
        "house.fill", "door.left.hand.closed", "window.horizontal.closed",
        "faucet.fill", "bathtub.fill", "sink.fill"
    ]
}
