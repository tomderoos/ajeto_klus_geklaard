import SwiftUI
import SwiftData

struct RoomsSheetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.sortOrder) private var rooms: [Room]

    @State private var editingRoom: Room?
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                if rooms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(AjetoColor.muted)
                        Text("Nog geen ruimtes").ajTitle()
                        Text("Voeg een ruimte toe om je klussen te organiseren.")
                            .ajCaption()
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(rooms) { room in
                                Button {
                                    editingRoom = room
                                } label: {
                                    RoomRow(room: room)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(room)
                                    } label: {
                                        Label("Verwijderen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Ruimtes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Gereed") { dismiss() }
                        .font(AjetoFont.body(15, weight: .semibold))
                        .foregroundStyle(AjetoColor.ink)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNew = true
                    } label: {
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
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    RoomEditView(mode: .create(nextSortOrder: (rooms.last?.sortOrder ?? -1) + 1))
                }
            }
            .sheet(item: $editingRoom) { room in
                NavigationStack {
                    RoomEditView(mode: .edit(room))
                }
            }
        }
    }
}

private struct RoomRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous)
                    .fill(AjetoColor.mint)
                Image(systemName: room.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AjetoColor.greenInk)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(AjetoFont.display(16, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                Text("\(room.chores?.count ?? 0) klus\((room.chores?.count ?? 0) == 1 ? "" : "sen")")
                    .font(AjetoFont.body(12, weight: .medium))
                    .foregroundStyle(AjetoColor.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AjetoColor.faint)
        }
        .ajCard(padding: 12)
    }
}
