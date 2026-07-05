import SwiftUI
import SwiftData
import UIKit

struct ImportChorePreviewView: View {
    let snapshot: ChoreSnapshot
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        if !snapshot.photos.isEmpty {
                            PhotoStrip(photos: snapshot.photos)
                        }
                        DetailsCard(snapshot: snapshot)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Klus ontvangen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Nee, bedankt") { onCancel() }
                        .font(AjetoFont.body(15, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Overnemen") { onConfirm() }
                        .font(AjetoFont.body(15, weight: .bold))
                        .foregroundStyle(AjetoColor.blue)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Iemand deelt een klus met je").ajEyebrow(AjetoColor.muted)
            Text(snapshot.title.isEmpty ? "Zonder titel" : snapshot.title)
                .font(AjetoFont.display(26, weight: .bold))
                .tracking(-0.6)
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
