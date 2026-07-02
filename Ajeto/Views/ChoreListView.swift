import SwiftUI
import SwiftData

struct ChoreListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Chore.createdAt, order: .reverse) private var allChores: [Chore]

    @State private var showingNew = false

    private var chores: [Chore] {
        allChores.sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone { return !lhs.isDone && rhs.isDone }
            switch (lhs.scheduledStart, rhs.scheduledStart) {
            case let (l?, r?): return l < r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.createdAt > rhs.createdAt
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                if chores.isEmpty {
                    EmptyState()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chores) { chore in
                                NavigationLink {
                                    ChoreDetailView(chore: chore)
                                } label: {
                                    ChoreRow(chore: chore)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(chore)
                                    } label: {
                                        Label("Verwijderen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Klussen")
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AddButton { showingNew = true }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack { ChoreEditView(mode: .create) }
            }
        }
    }

    private func delete(_ chore: Chore) {
        for photo in chore.photos {
            PhotoStorage.delete(photo.filename)
        }
        context.delete(chore)
    }
}

private struct AddButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(AjetoColor.green)
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AjetoColor.ink)
            }
            .frame(width: 34, height: 34)
        }
    }
}

private struct EmptyState: View {
    var body: some View {
        VStack(spacing: 22) {
            AjetoBrandIcon(size: 96, glow: true)
            VStack(spacing: 8) {
                Text("Nog geen klussen").ajTitle()
                Text("Tik op + om je eerste klus toe te voegen.")
                    .ajCaption()
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

private struct ChoreRow: View {
    let chore: Chore

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 6) {
                Text(chore.title.isEmpty ? "Zonder titel" : chore.title)
                    .font(AjetoFont.display(17, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(chore.isDone ? AjetoColor.muted : AjetoColor.ink)
                    .strikethrough(chore.isDone)
                if let start = chore.scheduledStart {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                        Text(start.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(AjetoFont.body(13, weight: .medium))
                    .foregroundStyle(AjetoColor.muted)
                }
            }
            Spacer(minLength: 0)
            if chore.isDone {
                DoneBadge()
            }
        }
        .ajCard(padding: 14)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let filename = chore.photos.first?.filename,
           let image = PhotoStorage.load(filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous))
        } else {
            AjetoBrandIcon(size: 56, background: AjetoColor.mint, checkColor: AjetoColor.green)
        }
    }
}

private struct DoneBadge: View {
    var body: some View {
        ZStack {
            Circle().fill(AjetoColor.green)
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AjetoColor.ink)
        }
        .frame(width: 26, height: 26)
    }
}
