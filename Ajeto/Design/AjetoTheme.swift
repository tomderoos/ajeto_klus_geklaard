import SwiftUI

enum AjetoColor {
    static let green      = Color(hex: 0x12CE8E)
    static let greenInk   = Color(hex: 0x0B2E22)
    static let blue       = Color(hex: 0x2563FF)
    static let ink        = Color(hex: 0x0B1F3A)

    static let mint       = Color(hex: 0xE5F4EC)
    static let sky        = Color(hex: 0xEAF1FF)
    static let paper      = Color(hex: 0xF6F9FC)
    static let surface    = Color.white
    static let border     = Color(hex: 0xEAF0F6)
    static let muted      = Color(hex: 0x6D8296)
    static let faint      = Color(hex: 0xA6B3C2)

    static let onDarkAccent = Color(hex: 0x58E0AE)
}

enum AjetoRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let iconRatio: CGFloat = 0.28
}

enum AjetoShadow {
    static let card = Shadow(
        color: Color(hex: 0x0B1F3A).opacity(0.12),
        radius: 35, x: 0, y: 15
    )
    static let green = Shadow(
        color: AjetoColor.green.opacity(0.45),
        radius: 18, x: 0, y: 10
    )

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

enum AjetoFont {
    static let displayFamily = "Space Grotesk"
    static let bodyFamily    = "Hanken Grotesk"

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(displayFamily, size: size).weight(weight)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(bodyFamily, size: size).weight(weight)
    }
}

extension View {
    func ajTitle() -> some View {
        self.font(AjetoFont.display(28, weight: .bold))
            .tracking(-0.6)
            .foregroundStyle(AjetoColor.ink)
    }

    func ajHeadline() -> some View {
        self.font(AjetoFont.display(17, weight: .semibold))
            .foregroundStyle(AjetoColor.ink)
    }

    func ajBody() -> some View {
        self.font(AjetoFont.body(15, weight: .regular))
            .foregroundStyle(AjetoColor.ink)
    }

    func ajCaption(_ color: Color = AjetoColor.muted) -> some View {
        self.font(AjetoFont.body(13, weight: .regular))
            .foregroundStyle(color)
    }

    func ajEyebrow(_ color: Color = AjetoColor.blue) -> some View {
        self.font(AjetoFont.display(11, weight: .medium))
            .tracking(1.7)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

extension View {
    func ajCard(padding: CGFloat = 16, radius: CGFloat = AjetoRadius.lg) -> some View {
        self
            .padding(padding)
            .background(AjetoColor.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AjetoColor.border, lineWidth: 1)
            )
            .shadow(
                color: AjetoShadow.card.color,
                radius: AjetoShadow.card.radius,
                x: AjetoShadow.card.x,
                y: AjetoShadow.card.y
            )
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
