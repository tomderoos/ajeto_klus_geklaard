import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("userName") private var userName: String = ""

    @State private var page: Int = 0
    @State private var nameInput: String = ""
    @FocusState private var nameFocused: Bool

    private let steps: [OnboardingStep] = OnboardingStep.all

    private var isLast: Bool { page == steps.count - 1 }
    private var isNameStep: Bool {
        if case .nameEntry = steps[page] { return true } else { return false }
    }
    private var trimmedName: String {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canProceed: Bool {
        isNameStep ? !trimmedName.isEmpty : true
    }

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        StepView(
                            step: step,
                            nameInput: $nameInput,
                            nameFocused: $nameFocused
                        )
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
        .onChange(of: page) { _, newPage in
            if case .nameEntry = steps[newPage] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nameFocused = true
                }
            } else {
                nameFocused = false
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
            ForEach(steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? AjetoColor.green : AjetoColor.border)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: page)
            }
        }
    }

    private var primaryButton: some View {
        Button {
            handlePrimaryTap()
        } label: {
            HStack(spacing: 8) {
                Text(isLast ? "Aan de slag" : "Volgende")
                    .font(AjetoFont.display(16, weight: .bold))
                if !isLast {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(canProceed ? AjetoColor.ink : AjetoColor.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canProceed ? AjetoColor.green : AjetoColor.border, in: Capsule())
            .shadow(color: canProceed ? AjetoColor.green.opacity(0.35) : .clear, radius: 18, x: 0, y: 10)
        }
        .disabled(!canProceed)
    }

    private func handlePrimaryTap() {
        if isLast {
            if isNameStep {
                saveName()
            }
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                page += 1
            }
        }
    }

    private func saveName() {
        let name = trimmedName
        guard !name.isEmpty else { return }
        userName = name
        _ = Person.findOrCreate(
            name: name,
            in: context,
            household: Household.primary(in: context)
        )
    }
}

private enum OnboardingStep {
    case slide(OnboardingSlide)
    case nameEntry

    static let all: [OnboardingStep] = [
        .slide(OnboardingSlide(
            eyebrow: "WELKOM",
            title: "Ajeto!",
            body: "Houd bij wat er in en om het huis moet gebeuren, van 'lampje vervangen' tot 'zolder opknappen'. Vink af wat je hebt gedaan.",
            visual: .brandIcon
        )),
        .slide(OnboardingSlide(
            eyebrow: "01 · KLUSSEN",
            title: "Klus geklaard, met foto's",
            body: "Maak een klus aan met titel, beschrijving, en foto's van voor en na. Plan een start- en eindtijd als je 'm inplant.",
            visual: .symbol("checkmark.circle.fill",
                            background: AjetoColor.mint,
                            foreground: AjetoColor.greenInk)
        )),
        .slide(OnboardingSlide(
            eyebrow: "02 · ORGANISEER",
            title: "Ruimtes en projecten",
            body: "Groepeer klussen per ruimte (Woonkamer, Tuin, WC…) of vat ze samen tot een project (Zolder opknappen, Huis verkoop klaar maken). Filter met één tik.",
            visual: .symbol("square.stack.3d.up.fill",
                            background: AjetoColor.sky,
                            foreground: AjetoColor.blue)
        )),
        .slide(OnboardingSlide(
            eyebrow: "03 · SAMEN",
            title: "Verdeel het werk",
            body: "Voeg jezelf en huisgenoten toe als personen en wijs ze toe aan klussen. In Planning filter je op één persoon om te zien wat jij vandaag moet doen.",
            visual: .symbol("person.2.fill",
                            background: AjetoColor.mint,
                            foreground: AjetoColor.greenInk)
        )),
        .slide(OnboardingSlide(
            eyebrow: "04 · SYNC & DELEN",
            title: "Overal je klussen",
            body: "Klussen syncen automatisch tussen jouw Apple-apparaten via iCloud. Deel een enkele klus of je hele lijst met iemand anders via de deel-knop.",
            visual: .symbol("icloud.fill",
                            background: AjetoColor.sky,
                            foreground: AjetoColor.blue)
        )),
        .nameEntry
    ]
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
}

private struct StepView: View {
    let step: OnboardingStep
    @Binding var nameInput: String
    var nameFocused: FocusState<Bool>.Binding

    var body: some View {
        switch step {
        case .slide(let slide):
            SlideView(slide: slide)
        case .nameEntry:
            NameEntryView(name: $nameInput, focused: nameFocused)
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

private struct NameEntryView: View {
    @Binding var name: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(AjetoColor.mint)
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(AjetoColor.greenInk)
            }
            .frame(width: 132, height: 132)
            .shadow(color: AjetoColor.greenInk.opacity(0.15), radius: 24, x: 0, y: 12)

            VStack(spacing: 12) {
                Text("HOE MOETEN WE JE NOEMEN?").ajEyebrow(AjetoColor.blue)
                Text("Wat is je voornaam?")
                    .font(AjetoFont.display(28, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(AjetoColor.ink)
                    .multilineTextAlignment(.center)
                Text("Zo herkennen huisgenoten je en kun je klussen aan jezelf toewijzen.")
                    .font(AjetoFont.body(15, weight: .regular))
                    .foregroundStyle(AjetoColor.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            TextField("Voornaam", text: $name)
                .font(AjetoFont.display(20, weight: .semibold))
                .foregroundStyle(AjetoColor.ink)
                .tint(AjetoColor.green)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(AjetoColor.surface, in: Capsule())
                .overlay(
                    Capsule().stroke(AjetoColor.border, lineWidth: 1)
                )
                .focused(focused)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Chore.self, ChorePhoto.self, Room.self, Household.self, Person.self, Project.self], inMemory: true)
}
