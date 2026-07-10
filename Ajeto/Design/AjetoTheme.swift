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
    static let sm: CGFloat = 12
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let iconRatio: CGFloat = 0.28
}

enum AjetoShadow {
    static let card = Shadow(
        color: Color(hex: 0x10171C).opacity(0.10),
        radius: 35, x: 0, y: 15
    )
    static let green = Shadow(
        color: AjetoColor.green.opacity(0.35),
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
    // Huisstijl 1c: Fredoka (rond, vriendelijk) voor koppen en logo,
    // Nunito (helder, breed weight-range) voor body en UI-tekst.
    static let displayFamily = "Fredoka"
    static let bodyFamily    = "Nunito"

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
