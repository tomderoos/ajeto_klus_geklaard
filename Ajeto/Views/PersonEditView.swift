import SwiftUI
import SwiftData

struct PersonEditView: View {
    enum Mode {
        case create(nextSortOrder: Int, defaultColor: UInt32)
        case edit(Person)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorHex: UInt32 = 0x12CE8E
    @State private var didLoad = false

    private var editingPerson: Person? {
        if case .edit(let p) = mode { return p }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Live preview-person die alleen gebruikt wordt om PersonAvatar te
    /// renderen; nooit ingevoegd in de context.
    private var previewPerson: Person {
        let p = Person(name: name.isEmpty ? "?" : name, colorHex: colorHex)
        return p
    }

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        PersonAvatar(person: previewPerson, size: 96)
                        Text(name.isEmpty ? "Zonder naam" : name)
                            .font(AjetoFont.display(20, weight: .bold))
                            .tracking(-0.3)
                            .foregroundStyle(AjetoColor.ink)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Naam").ajEyebrow(AjetoColor.muted)
                        VStack {
                            TextField("Bv. Tom", text: $name)
                                .font(AjetoFont.body(15, weight: .medium))
                                .foregroundStyle(AjetoColor.ink)
                                .tint(AjetoColor.blue)
                        }
                        .ajCard(padding: 14)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kleur").ajEyebrow(AjetoColor.muted)
                        ColorPalette(selected: $colorHex)
                            .ajCard(padding: 12)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(editingPerson == nil ? "Nieuwe persoon" : "Persoon bewerken")
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
            switch mode {
            case .create(_, let defaultColor):
                colorHex = defaultColor
            case .edit(let person):
                name = person.name
                colorHex = person.colorHex
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .create(let sortOrder, _):
            let person = Person(name: trimmed, colorHex: colorHex, sortOrder: sortOrder)
            person.household = Household.primary(in: context)
            context.insert(person)
        case .edit(let person):
            person.name = trimmed
            person.colorHex = colorHex
        }
        dismiss()
    }
}

private struct ColorPalette: View {
    @Binding var selected: UInt32

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Person.palette, id: \.self) { hex in
                Button {
                    selected = hex
                } label: {
                    ZStack {
                        Circle().fill(Color(hex: hex))
                        if selected == hex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 40)
                    .overlay(
                        Circle().stroke(Color.white.opacity(selected == hex ? 0.9 : 0), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
