import SwiftUI

enum AjetoColor {
    // Huisstijl 1c: donker-groen primary + warm goud accent op grijs-wit surface.
    // Variabele-namen blijven historisch (green/blue/mint/sky) zodat views niet
    // aangeraakt hoeven te worden; alleen de hex-waarden veranderen mee.
    static let green      = Color(hex: 0x269143) // primary
    static let greenInk   = Color(hex: 0x005F1D) // primary deep
    static let blue       = Color(hex: 0xDAA42F) // accent (goud)
    static let ink        = Color(hex: 0x10171C) // text

    static let mint       = Color(hex: 0xC1E6C5) // primary soft
    static let sky        = Color(hex: 0xF9E1B8) // accent soft
    static let paper      = Color(hex: 0xF7F9FA) // background
    static let surface    = Color.white
    static let border     = Color(hex: 0xDEE2E5)
    static let muted      = Color(hex: 0x5D646A) // text muted
    static let faint      = Color(hex: 0xA8AFB5) // grayscale tussen border en muted

    static let onDarkAccent = Color(hex: 0x7CC890) // primary variant voor donkere vlakken
}

enum AjetoRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 16
    static let iconRatio: CGFloat = 0.28
}

enum AjetoShadow {
    // Zeer subtiel — geeft nog net lift tegen de paper-achtergrond, maar
    // niet meer de zware drop-shadow uit huisstijl 1c.
    static let card = Shadow(
        color: Color(hex: 0x10171C).opacity(0.05),
        radius: 6, x: 0, y: 2
    )
    static let green = Shadow(
        color: AjetoColor.green.opacity(0.12),
        radius: 6, x: 0, y: 3
    )

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

enum AjetoFont {
    // SF Pro via SwiftUI's default systeem-font. Geen custom font-file meer
    // nodig — snellere textinput, geen render-lag. `display` en `body`
    // blijven bestaan zodat views niet aangeraakt hoeven te worden; het
    // onderscheid zit alleen nog in default weight.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

extension View {
    func ajTitle() -> some View {
        self.font(AjetoFont.display(26, weight: .semibold))
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

    func ajEyebrow(_ color: Color = AjetoColor.muted) -> some View {
        self.font(AjetoFont.body(11, weight: .medium))
            .tracking(0.8)
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
