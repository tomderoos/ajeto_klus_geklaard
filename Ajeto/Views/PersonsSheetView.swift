import SwiftUI
import SwiftData

struct PersonsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Person.sortOrder) private var persons: [Person]

    @State private var showingNew = false
    @State private var editing: Person?

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                if persons.isEmpty {
                    EmptyState { showingNew = true }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(persons) { person in
                                Button {
                                    editing = person
                                } label: {
                                    PersonRow(person: person)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(person)
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
            .navigationTitle("Personen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { dismiss() }
                        .font(AjetoFont.body(15, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
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
                    PersonEditView(mode: .create(
                        nextSortOrder: (persons.last?.sortOrder ?? -1) + 1,
                        defaultColor: Person.nextColor(existingCount: persons.count)
                    ))
                }
            }
            .sheet(item: $editing) { person in
                NavigationStack {
                    PersonEditView(mode: .edit(person))
                }
            }
        }
    }

    private func delete(_ person: Person) {
        context.delete(person)
    }
}

private struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 14) {
            PersonAvatar(person: person, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(AjetoFont.display(16, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                let count = person.assignedChores?.count ?? 0
                Text("\(count) klus\(count == 1 ? "" : "sen")")
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

private struct EmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 40)
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AjetoColor.mint)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AjetoColor.greenInk)
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 8) {
                Text("Nog geen personen").ajTitle().multilineTextAlignment(.center)
                Text("Voeg jezelf en huisgenoten toe om klussen te verdelen.")
                    .ajCaption()
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Nieuwe persoon")
                        .font(AjetoFont.body(14, weight: .bold))
                }
                .foregroundStyle(AjetoColor.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(AjetoColor.green, in: Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}
