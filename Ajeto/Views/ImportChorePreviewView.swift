import SwiftUI
import SwiftData
import UIKit

struct ImportChorePreviewView: View {
    let bundle: ChoresBundle
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Header(bundle: bundle)
                        if bundle.chores.count == 1, let single = bundle.chores.first {
                            SingleContent(snapshot: single)
                        } else {
                            BundleContent(bundle: bundle)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(bundle.chores.count == 1 ? "Klus ontvangen" : "Klussen ontvangen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Nee, bedankt") { onCancel() }
                        .font(AjetoFont.body(15, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel) { onConfirm() }
                        .font(AjetoFont.body(15, weight: .bold))
                        .foregroundStyle(AjetoColor.blue)
                }
            }
        }
    }

    private var confirmLabel: String {
        bundle.chores.count == 1
            ? "Overnemen"
            : "Alle \(bundle.chores.count) overnemen"
    }
}

// MARK: - Header

private struct Header: View {
    let bundle: ChoresBundle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bundle.chores.count == 1
                 ? "Iemand deelt een klus met je"
                 : "Iemand deelt \(bundle.chores.count) klussen met je"
            )
            .ajEyebrow(AjetoColor.muted)

            Text("Verstuurd op \(exportedAtText)")
                .font(AjetoFont.body(13, weight: .medium))
                .foregroundStyle(AjetoColor.muted)
        }
    }

    private var exportedAtText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: bundle.exportedAt)
    }
}

// MARK: - Single-item content

private struct SingleContent: View {
    let snapshot: ChoreSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(snapshot.title.isEmpty ? "Zonder titel" : snapshot.title)
                .font(AjetoFont.display(24, weight: .semibold))
                .foregroundStyle(AjetoColor.ink)

            if let roomName = snapshot.roomName {
                HStack(spacing: 5) {
                    Image(systemName: snapshot.roomIconName ?? "square.dashed")
                        .font(.system(size: 11, weight: .semibold))
                    Text(roomName)
                        .font(AjetoFont.body(12, weight: .semibold))
                }
                .foregroundStyle(AjetoColor.greenInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AjetoColor.mint, in: Capsule())
            }

            if !snapshot.photos.isEmpty {
                PhotoStrip(photos: snapshot.photos)
            }

            DetailsCard(snapshot: snapshot)
        }
    }
}

private struct PhotoStrip: View {
    let photos: [ChoreSnapshot.PhotoSnapshot]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.offset) { _, snap in
                    if let image = UIImage(data: snap.data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: AjetoRadius.md, style: .continuous))
                    }
                }
            }
        }
    }
}

private struct DetailsCard: View {
    let snapshot: ChoreSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let start = snapshot.scheduledStart {
                InfoLine(icon: "calendar", label: "Planning") {
                    if let end = snapshot.scheduledEnd {
                        Text("\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                    } else {
                        Text(start.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
            let trimmed = snapshot.details.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Beschrijving").ajEyebrow(AjetoColor.muted)
                    Text(trimmed).ajBody()
                }
            }
            if snapshot.isDone {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AjetoColor.green)
                    Text("Al afgevinkt door de afzender")
                        .font(AjetoFont.body(13, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                }
            }
        }
        .ajCard(padding: 16)
    }
}

private struct InfoLine<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label)
            }
            .ajEyebrow(AjetoColor.muted)
            content()
                .font(AjetoFont.body(15, weight: .medium))
                .foregroundStyle(AjetoColor.ink)
        }
    }
}

// MARK: - Bundle (multi-item) content

private struct BundleContent: View {
    let bundle: ChoresBundle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SummaryCard(bundle: bundle)
            VStack(spacing: 10) {
                ForEach(Array(bundle.chores.enumerated()), id: \.offset) { _, snap in
                    BundleRow(snapshot: snap)
                }
            }
        }
    }
}

private struct SummaryCard: View {
    let bundle: ChoresBundle

    var body: some View {
        HStack(spacing: 14) {
            AjetoBrandIcon(size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(bundle.chores.count) klussen").font(AjetoFont.display(19, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                Text(counts).ajCaption()
            }
        }
        .ajCard(padding: 14)
    }

    private var counts: String {
        let withPhoto = bundle.chores.filter { !$0.photos.isEmpty }.count
        let scheduled = bundle.chores.filter { $0.scheduledStart != nil }.count
        let done = bundle.chores.filter { $0.isDone }.count
        var parts: [String] = []
        if withPhoto > 0 { parts.append("\(withPhoto) met foto") }
        if scheduled > 0 { parts.append("\(scheduled) ingepland") }
        if done > 0 { parts.append("\(done) al klaar") }
        return parts.isEmpty ? "Klaar om over te nemen." : parts.joined(separator: " · ")
    }
}

private struct BundleRow: View {
    let snapshot: ChoreSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.title.isEmpty ? "Zonder titel" : snapshot.title)
                    .font(AjetoFont.display(15, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                HStack(spacing: 8) {
                    if let roomName = snapshot.roomName {
                        HStack(spacing: 4) {
                            Image(systemName: snapshot.roomIconName ?? "square.dashed")
                                .font(.system(size: 9, weight: .semibold))
                            Text(roomName)
                                .font(AjetoFont.body(10, weight: .semibold))
                        }
                        .foregroundStyle(AjetoColor.greenInk)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AjetoColor.mint, in: Capsule())
                    }
                    if let start = snapshot.scheduledStart {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .semibold))
                            Text(start.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(AjetoFont.body(11, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                    }
                }
            }
            Spacer(minLength: 0)
            if snapshot.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AjetoColor.green)
            }
        }
        .ajCard(padding: 12)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let first = snapshot.photos.first, let image = UIImage(data: first.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous))
        } else {
            AjetoBrandIcon(size: 44, background: AjetoColor.mint, checkColor: AjetoColor.green)
        }
    }
}
