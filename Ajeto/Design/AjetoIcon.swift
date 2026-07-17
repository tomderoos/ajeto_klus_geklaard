import SwiftUI

/// Ajeto-merkteken: groene squircle + navy vinkje.
/// Schaalt mee met de aangegeven `size`. Squircle-radius is 28% van de zijde.
struct AjetoBrandIcon: View {
    var size: CGFloat = 56
    var background: Color = AjetoColor.green
    var checkColor: Color = AjetoColor.ink
    var glow: Bool = false

    var body: some View {
        let radius = size * AjetoRadius.iconRatio

        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(background)
            CheckmarkShape()
                .stroke(
                    checkColor,
                    style: StrokeStyle(
                        lineWidth: max(4, size * 0.125),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .padding(size * 0.22)
        }
        .frame(width: size, height: size)
        .shadow(
            color: glow ? AjetoShadow.green.color : .clear,
            radius: AjetoShadow.green.radius,
            x: 0, y: AjetoShadow.green.y
        )
    }
}

/// De checkmark uit het merkteken (viewBox 48×48, path "M12 25 l8 8 l17 -20"),
/// genormaliseerd op 0…1 zodat hij in een SwiftUI rect past.
private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Origineel viewBox 48×48, path start (12,25), midden (20,33), eind (37,13).
        // We nemen alleen het bounding-box gebied dat het pad gebruikt en spreiden dat
        // uit over de meegegeven rect (kleiner geheel na padding).
        let p1 = CGPoint(x: (12 - 12) / 25.0, y: (25 - 13) / 20.0)
        let p2 = CGPoint(x: (20 - 12) / 25.0, y: (33 - 13) / 20.0)
        let p3 = CGPoint(x: (37 - 12) / 25.0, y: (13 - 13) / 20.0)

        func map(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x * rect.width,
                    y: rect.minY + p.y * rect.height)
        }

        var path = Path()
        path.move(to: map(p1))
        path.addLine(to: map(p2))
        path.addLine(to: map(p3))
        return path
    }
}

/// Horizontale lockup — icoon + "Ajeto!" woordmerk (uitroepteken in accent-goud),
/// eventueel tagline eronder. Systeem-serif semibold voor het woordmerk.
struct AjetoLogoLockup: View {
    var iconSize: CGFloat = 44
    var showTagline: Bool = false
    var onDark: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            AjetoBrandIcon(size: iconSize)
            VStack(alignment: .leading, spacing: 2) {
                wordmark
                if showTagline {
                    Text("Klus geklaard")
                        .font(AjetoFont.body(max(9, iconSize * 0.22), weight: .medium))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(onDark ? AjetoColor.onDarkAccent : AjetoColor.muted)
                }
            }
        }
    }

    private var wordmark: some View {
        let size = iconSize * 0.72
        return HStack(spacing: 0) {
            Text("Ajeto")
                .foregroundStyle(onDark ? Color.white : AjetoColor.ink)
            Text("!")
                .foregroundStyle(AjetoColor.blue) // accent goud
        }
        .font(AjetoFont.display(size, weight: .semibold))
    }
}

#Preview("Brand icon") {
    VStack(spacing: 24) {
        AjetoBrandIcon(size: 120, glow: true)
        AjetoLogoLockup(iconSize: 56, showTagline: true)
    }
    .padding(40)
    .background(AjetoColor.paper)
}
