import SwiftUI

struct BulkSharePayload: Identifiable {
    let id = UUID()
    let url: URL
    let count: Int
    let exportedAt: Date
}

/// Tussensheet die bevestigt hoeveel klussen er in het exportbestand zitten en
/// wanneer de export gemaakt is, met daaronder een groene ShareLink om iOS' eigen
/// share sheet op te roepen.
struct BulkShareSheet: View {
    let payload: BulkSharePayload
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer(minLength: 12)

                    AjetoBrandIcon(size: 108, glow: true)

                    VStack(spacing: 8) {
                        Text("\(payload.count) klussen gebundeld")
                            .font(AjetoFont.display(22, weight: .semibold))
                            .foregroundStyle(AjetoColor.ink)
                            .multilineTextAlignment(.center)
                        Text("Momentopname van \(exportedAtText)")
                            .font(AjetoFont.body(13, weight: .medium))
                            .foregroundStyle(AjetoColor.muted)
                            .multilineTextAlignment(.center)
                    }

                    ShareLink(item: payload.url, subject: Text("Ajeto klussen (\(payload.count))")) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Delen")
                                .font(AjetoFont.display(16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AjetoColor.green, in: Capsule())
                    }
                    .padding(.horizontal, 16)

                    Text("Het bestand heet **\(filenameForDisplay)** en bevat alle titels, planningen, ruimtes en foto's.")
                        .font(AjetoFont.body(12, weight: .regular))
                        .foregroundStyle(AjetoColor.faint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .navigationTitle("Klaar om te delen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { dismiss() }
                        .font(AjetoFont.body(15, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                }
            }
        }
    }

    private var exportedAtText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: payload.exportedAt)
    }

    private var filenameForDisplay: String {
        payload.url.lastPathComponent
    }
}
