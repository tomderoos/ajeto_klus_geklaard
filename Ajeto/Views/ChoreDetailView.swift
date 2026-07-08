import SwiftUI
import SwiftData

struct ChoreDetailView: View {
    @Bindable var chore: Chore
    @State private var showingEdit = false
    @State private var shareURL: URL?

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !chore.photosList.isEmpty {
                        PhotoGalleryView(photos: chore.photosList)
                            .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        StatusToggle(chore: chore)

                        if let room = chore.room {
                            InfoRow(icon: "square.grid.2x2", label: "Ruimte") {
                                HStack(spacing: 6) {
                                    Image(systemName: room.iconName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(room.name)
                                }
                            }
                        }

                        if let assignees = chore.assignees, !assignees.isEmpty {
                            AssigneeRow(persons: assignees)
                        }

                        if let start = chore.scheduledStart {
                            InfoRow(icon: "calendar", label: "Planning") {
                                if let end = chore.scheduledEnd {
                                    Text("\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                                } else {
                                    Text(start.formatted(date: .abbreviated, time: .shortened))
                                }
                            }
                        }

                        if !chore.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Beschrijving").ajEyebrow(AjetoColor.muted)
                                Text(chore.details).ajBody()
                            }
                        }
                    }
                    .ajCard(padding: 18)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(chore.title.isEmpty ? "Klus" : chore.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AjetoColor.paper, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let shareURL {
                    ShareLink(item: shareURL, subject: Text(chore.title.isEmpty ? "Klus" : chore.title)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AjetoColor.ink)
                    }
                }
                Button("Bewerken") { showingEdit = true }
                    .font(AjetoFont.body(15, weight: .semibold))
                    .foregroundStyle(AjetoColor.blue)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack { ChoreEditView(mode: .edit(chore)) }
        }
        .task(id: shareIdentity) {
            shareURL = try? ChoreExport.writeTempFile(for: chore)
        }
    }

    /// Verandert wanneer de klus-inhoud verandert, zodat het gedeelde bestand
    /// automatisch opnieuw wordt aangemaakt na een edit.
    private var shareIdentity: String {
        "\(chore.title)|\(chore.details)|\(chore.photosList.count)|\(chore.scheduledStart?.timeIntervalSince1970 ?? 0)|\(chore.isDone)|\(chore.room?.name ?? "")"
    }
}

private struct StatusToggle: View {
    @Bindable var chore: Chore

    var body: some View {
        Button {
            chore.isDone.toggle()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(chore.isDone ? AjetoColor.green : AjetoColor.mint)
                    if chore.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AjetoColor.ink)
                    }
                }
                .frame(width: 30, height: 30)
                .overlay(
                    Circle().strokeBorder(chore.isDone ? .clear : AjetoColor.green.opacity(0.5), lineWidth: 1.5)
                )
                Text(chore.isDone ? "Klaar" : "Nog te doen")
                    .font(AjetoFont.display(15, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AssigneeRow: View {
    let persons: [Person]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.2")
                    .font(.system(size: 11, weight: .semibold))
                Text("Wie doet dit")
            }
            .ajEyebrow(AjetoColor.muted)

            FlowLayout(spacing: 8) {
                ForEach(persons) { person in
                    HStack(spacing: 6) {
                        PersonAvatar(person: person, size: 22)
                        Text(person.name)
                            .font(AjetoFont.body(13, weight: .semibold))
                            .foregroundStyle(AjetoColor.ink)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AjetoColor.mint.opacity(0.5), in: Capsule())
                }
            }
        }
    }
}

/// Simpele HStack die op de volgende regel breekt als het niet meer past.
/// Voor kleine chip-collecties (personen, tags) — geen high-performance layout.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, currentRowWidth > 0 {
                totalHeight += currentRowHeight + spacing
                currentRowWidth = size.width + spacing
                currentRowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct InfoRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
            }
            .ajEyebrow(AjetoColor.muted)
            content()
                .font(AjetoFont.body(15, weight: .medium))
                .foregroundStyle(AjetoColor.ink)
        }
    }
}
