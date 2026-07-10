import SwiftUI
import CloudKit
import SwiftData

/// Startpunt van de "Nodig huisgenoot uit"-flow. Toont eerst een korte
/// uitleg + call-to-action; op tap gaat 'ie via HouseholdSharingService
/// asynchroon een CKShare voorbereiden en presenteert dan Apple's
/// UICloudSharingController voor het daadwerkelijke uitnodigen.
struct HouseholdShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var status: Status = .idle
    @State private var errorMessage: String?
    @State private var sharePayload: SharePayload?

    private enum Status {
        case idle
        case preparing
        case ready
    }

    struct SharePayload: Identifiable {
        let id = UUID()
        let share: CKShare
        let container: CKContainer
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                    hero
                    copy
                    Spacer(minLength: 0)
                    ctaButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Huisgenoot uitnodigen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { dismiss() }
                        .font(AjetoFont.body(15, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                }
            }
            .sheet(item: $sharePayload, onDismiss: { dismiss() }) { payload in
                HouseholdShareController(
                    share: payload.share,
                    container: payload.container,
                    onEnd: { sharePayload = nil }
                )
                .ignoresSafeArea()
            }
            .alert(
                "Kon niet delen",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(AjetoColor.mint)
            Image(systemName: "person.2.badge.gearshape.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(AjetoColor.greenInk)
        }
        .frame(width: 132, height: 132)
        .shadow(color: AjetoColor.greenInk.opacity(0.15), radius: 24, x: 0, y: 12)
    }

    private var copy: some View {
        VStack(spacing: 12) {
            Text("SAMEN KLUSSEN").ajEyebrow(AjetoColor.blue)
            Text("Deel je huishouden")
                .font(AjetoFont.display(24, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(AjetoColor.ink)
                .multilineTextAlignment(.center)
            Text("Nodig een huisgenoot uit via iMessage of Mail. Zij zien straks jullie klussen, ruimtes en projecten en kunnen ze afvinken.\n\nData van vóór deze uitnodiging blijft nog even alleen bij jou — de sync-migratie volgt in een aparte update.")
                .font(AjetoFont.body(14, weight: .regular))
                .foregroundStyle(AjetoColor.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    private var ctaButton: some View {
        Button {
            prepareShare()
        } label: {
            HStack(spacing: 10) {
                if status == .preparing {
                    ProgressView().tint(AjetoColor.ink)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                }
                Text(status == .preparing ? "Voorbereiden…" : "Uitnodiging maken")
                    .font(AjetoFont.display(16, weight: .bold))
            }
            .foregroundStyle(AjetoColor.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AjetoColor.green, in: Capsule())
            .shadow(color: AjetoColor.green.opacity(0.35), radius: 18, x: 0, y: 10)
        }
        .disabled(status == .preparing)
    }

    private func prepareShare() {
        guard let household = Household.primary(in: context) else {
            errorMessage = "Er is nog geen huishouden om te delen."
            return
        }
        status = .preparing
        Task {
            do {
                let (share, container) = try await HouseholdSharingService.shared
                    .prepareShare(for: household)
                await MainActor.run {
                    // Push bestaande klussen naar de shared zone zodat
                    // uitgenodigde huisgenoten ze straks zien.
                    HouseholdSyncEngine.shared.migrateExistingRecords()
                    status = .ready
                    sharePayload = SharePayload(share: share, container: container)
                }
            } catch {
                await MainActor.run {
                    status = .idle
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "Er ging iets mis bij het maken van de uitnodiging."
                }
            }
        }
    }
}
