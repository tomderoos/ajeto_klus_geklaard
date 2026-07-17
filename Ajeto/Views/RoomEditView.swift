import SwiftUI
import SwiftData

struct RoomEditView: View {
    enum Mode {
        case create(nextSortOrder: Int)
        case edit(Room)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var iconName = "square.dashed"
    @State private var didLoad = false

    private var editingRoom: Room? {
        if case .edit(let r) = mode { return r }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Preview
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AjetoRadius.md, style: .continuous)
                                .fill(AjetoColor.mint)
                            Image(systemName: iconName)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(AjetoColor.greenInk)
                        }
                        .frame(width: 96, height: 96)
                        Text(name.isEmpty ? "Zonder naam" : name)
                            .font(AjetoFont.display(20, weight: .semibold))
                            .foregroundStyle(AjetoColor.ink)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Naam").ajEyebrow(AjetoColor.muted)
                        VStack {
                            TextField("Bv. Zolder", text: $name)
                                .font(AjetoFont.body(15, weight: .medium))
                                .foregroundStyle(AjetoColor.ink)
                                .tint(AjetoColor.blue)
                        }
                        .ajCard(padding: 14)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icoon").ajEyebrow(AjetoColor.muted)
                        IconGrid(selected: $iconName)
                            .ajCard(padding: 10)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(editingRoom == nil ? "Nieuwe ruimte" : "Ruimte bewerken")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AjetoColor.paper, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleer") { dismiss() }
                    .font(AjetoFont.body(15, weight: .medium))
                    .foregroundStyle(AjetoColor.muted)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Bewaar", action: save)
                    .font(AjetoFont.body(15, weight: .bold))
                    .foregroundStyle(canSave ? AjetoColor.blue : AjetoColor.faint)
                    .disabled(!canSave)
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            if let room = editingRoom {
                name = room.name
                iconName = room.iconName
            } else {
                iconName = RoomDefaults.availableIcons.first ?? "square.dashed"
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .create(let sortOrder):
            let room = Room(name: trimmed, iconName: iconName, sortOrder: sortOrder)
            room.household = Household.primary(in: context)
            context.insert(room)
        case .edit(let room):
            room.name = trimmed
            room.iconName = iconName
        }
        dismiss()
    }
}

private struct IconGrid: View {
    @Binding var selected: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(RoomDefaults.availableIcons, id: \.self) { name in
                Button {
                    selected = name
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selected == name ? AjetoColor.green : AjetoColor.mint.opacity(0.6))
                        Image(systemName: name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selected == name ? AjetoColor.ink : AjetoColor.greenInk)
                    }
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
