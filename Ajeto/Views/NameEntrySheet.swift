import SwiftUI
import SwiftData

/// Aparte sheet voor het invoeren of wijzigen van de voornaam. Bewust
/// buiten de OnboardingView's TabView gehouden — een TextField in een
/// page-style TabView geeft trage keyboard-input op iOS.
struct NameEntrySheet: View {
    enum Mode {
        /// Post-onboarding: eerste keer, kan niet weggeklikt worden.
        case introduction
        /// Vanuit menu: kan geannuleerd worden.
        case change
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("userName") private var userName: String = ""

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                VStack(spacing: 24) {
                    hero
                    copy
                    field
                    Spacer(minLength: 0)
                    primaryButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                if case .change = mode {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuleer") { dismiss() }
                            .font(AjetoFont.body(15, weight: .medium))
                            .foregroundStyle(AjetoColor.muted)
                    }
                }
            }
            .onAppear {
                draft = userName
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    focused = true
                }
            }
        }
        .interactiveDismissDisabled(mode == .introduction)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AjetoColor.mint)
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AjetoColor.greenInk)
        }
        .frame(width: 96, height: 96)
    }

    private var copy: some View {
        VStack(spacing: 10) {
            Text(mode == .introduction ? "Nog een laatste ding" : "Jouw voornaam")
                .ajEyebrow()
            Text("Wat is je voornaam?")
                .font(AjetoFont.display(22, weight: .semibold))
                .foregroundStyle(AjetoColor.ink)
                .multilineTextAlignment(.center)
            Text("Zo herkennen huisgenoten je en kun je klussen aan jezelf toewijzen.")
                .font(AjetoFont.body(14, weight: .regular))
                .foregroundStyle(AjetoColor.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
        }
    }

    private var field: some View {
        TextField("Voornaam", text: $draft)
            .font(.title3.weight(.semibold))
            .foregroundStyle(AjetoColor.ink)
            .tint(AjetoColor.green)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AjetoColor.surface, in: Capsule())
            .overlay(Capsule().stroke(AjetoColor.border, lineWidth: 1))
            .focused($focused)
            .onSubmit { commitAndDismiss() }
    }

    private var primaryButton: some View {
        Button {
            commitAndDismiss()
        } label: {
            Text(mode == .introduction ? "Aan de slag" : "Bewaar")
                .font(AjetoFont.display(16, weight: .semibold))
                .foregroundStyle(canSave ? .white : AjetoColor.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave ? AjetoColor.green : AjetoColor.border, in: Capsule())
        }
        .disabled(!canSave)
    }

    private func commitAndDismiss() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Bestaande "ik"-Person hernoemen als naam-match klopte, anders nieuw
        // maken via Person.findOrCreate. Zo blijven eerdere klus-toewijzingen
        // intact bij een naam-wijziging.
        let old = userName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !old.isEmpty,
           let all = try? context.fetch(FetchDescriptor<Person>()),
           let existing = all.first(where: { $0.name.lowercased() == old }) {
            existing.name = trimmed
            try? context.save()
        } else {
            _ = Person.findOrCreate(
                name: trimmed,
                in: context,
                household: Household.primary(in: context)
            )
        }
        userName = trimmed
        dismiss()
    }
}
