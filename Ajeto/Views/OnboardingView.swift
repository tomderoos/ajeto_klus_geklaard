import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page: Int = 0

    private let pages: [OnboardingSlide] = OnboardingSlide.all

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, slide in
                        SlideView(slide: slide)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
                    .padding(.top, 8)

                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
            }
        }
    }

    private var topBar: some View {
        HStack {
            AjetoLogoLockup(iconSize: 28, showTagline: false)
            Spacer()
            if !isLast {
                Button("Sla over") { dismiss() }
                    .font(AjetoFont.body(14, weight: .semibold))
                    .foregroundStyle(AjetoColor.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? AjetoColor.green : AjetoColor.border)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: page)
            }
        }
    }

    private var primaryButton: some View {
        Button {
            if isLast {
                dismiss()
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    page += 1
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(isLast ? "Volgende stap" : "Volgende")
                    .font(AjetoFont.display(16, weight: .bold))
                if !isLast {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(AjetoColor.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AjetoColor.green, in: Capsule())
            .shadow(color: AjetoColor.green.opacity(0.35), radius: 18, x: 0, y: 10)
        }
    }
}

private struct SlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 0)

            slideHero

            VStack(spacing: 12) {
                Text(slide.eyebrow).ajEyebrow(AjetoColor.blue)
                Text(slide.title)
                    .font(AjetoFont.display(28, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(AjetoColor.ink)
                    .multilineTextAlignment(.center)
                Text(slide.body)
                    .font(AjetoFont.body(15, weight: .regular))
                    .foregroundStyle(AjetoColor.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var slideHero: some View {
        switch slide.visual {
        case .brandIcon:
            AjetoBrandIcon(size: 132, glow: true)
        case .symbol(let name, let bg, let fg):
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(bg)
                Image(systemName: name)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(fg)
            }
            .frame(width: 132, height: 132)
            .shadow(color: fg.opacity(0.15), radius: 24, x: 0, y: 12)
        }
    }
}

private struct OnboardingSlide {
    let eyebrow: String
    let title: String
    let body: String
    let visual: Visual

    enum Visual {
        case brandIcon
        case symbol(String, background: Color, foreground: Color)
    }

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            eyebrow: "WELKOM",
            title: "Ajeto!",
            body: "Houd bij wat er in en om het huis moet gebeuren, van 'lampje vervangen' tot 'zolder opknappen'. Vink af wat je hebt gedaan.",
            visual: .brandIcon
        ),
        OnboardingSlide(
            eyebrow: "01 · KLUSSEN",
            title: "Klus geklaard, met foto's",
            body: "Maak een klus aan met titel, beschrijving, en foto's van voor en na. Plan een start- en eindtijd als je 'm inplant.",
            visual: .symbol("checkmark.circle.fill",
                            background: AjetoColor.mint,
                            foreground: AjetoColor.greenInk)
        ),
        OnboardingSlide(
            eyebrow: "02 · ORGANISEER",
            title: "Ruimtes en projecten",
            body: "Groepeer klussen per ruimte (Woonkamer, Tuin, WC…) of vat ze samen tot een project (Zolder opknappen, Huis verkoop klaar maken). Filter met één tik.",
            visual: .symbol("square.stack.3d.up.fill",
                            background: AjetoColor.sky,
                            foreground: AjetoColor.blue)
        ),
        OnboardingSlide(
            eyebrow: "03 · SAMEN",
            title: "Verdeel het werk",
            body: "Voeg jezelf en huisgenoten toe als personen en wijs ze toe aan klussen. In Planning filter je op één persoon om te zien wat jij vandaag moet doen.",
            visual: .symbol("person.2.fill",
                            background: AjetoColor.mint,
                            foreground: AjetoColor.greenInk)
        ),
        OnboardingSlide(
            eyebrow: "04 · SYNC & DELEN",
            title: "Overal je klussen",
            body: "Klussen syncen automatisch tussen jouw Apple-apparaten via iCloud. Deel een enkele klus of je hele lijst met iemand anders via de deel-knop.",
            visual: .symbol("icloud.fill",
                            background: AjetoColor.sky,
                            foreground: AjetoColor.blue)
        )
    ]
}

#Preview {
    OnboardingView()
}
