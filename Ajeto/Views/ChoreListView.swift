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
            Group {
                if chores.isEmpty {
                    ContentUnavailableView(
                        "Nog geen klussen",
                        systemImage: "hammer",
                        description: Text("Tik op + om je eerste klus toe te voegen.")
                    )
                } else {
                    List {
                        ForEach(chores) { chore in
                            NavigationLink {
                                ChoreDetailView(chore: chore)
                            } label: {
                                ChoreRow(chore: chore)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Klussen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    ChoreEditView(mode: .create)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let chore = chores[index]
            for photo in chore.photos {
                PhotoStorage.delete(photo.filename)
            }
            context.delete(chore)
        }
    }
}

private struct ChoreRow: View {
    let chore: Chore

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let filename = chore.photos.first?.filename,
               let image = PhotoStorage.load(filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "hammer")
                            .foregroundStyle(.secondary)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title.isEmpty ? "Zonder titel" : chore.title)
                    .font(.headline)
                    .strikethrough(chore.isDone)
                    .foregroundStyle(chore.isDone ? .secondary : .primary)
                if let start = chore.scheduledStart {
                    Text(start.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if chore.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}
