import SwiftUI
import SwiftData

struct ProjectEditView: View {
    enum Mode {
        case create
        case edit(Project)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var details = ""
    @State private var hasDeadline = false
    @State private var deadline = Date.now.addingTimeInterval(60 * 60 * 24 * 14) // +2 weken
    @State private var isCompleted = false
    @State private var didLoad = false

    private var editingProject: Project? {
        if case .edit(let p) = mode { return p }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Section(title: "Project") {
                        TextField("Naam (bv. Zolder opknappen)", text: $name)
                            .font(AjetoFont.body(15, weight: .medium))
                            .foregroundStyle(AjetoColor.ink)
                            .tint(AjetoColor.blue)
                        TextField("Omschrijving (optioneel)", text: $details, axis: .vertical)
                            .font(AjetoFont.body(15, weight: .regular))
                            .foregroundStyle(AjetoColor.ink)
                            .tint(AjetoColor.blue)
                            .lineLimit(2...6)
                    }

                    Section(title: "Deadline") {
                        Toggle(isOn: $hasDeadline.animation(.easeInOut(duration: 0.2))) {
                            Text("Streefdatum")
                                .font(AjetoFont.body(15, weight: .semibold))
                                .foregroundStyle(AjetoColor.ink)
                        }
                        .tint(AjetoColor.green)
                        if hasDeadline {
                            Divider().overlay(AjetoColor.border)
                            DatePicker("Klaar op", selection: $deadline, displayedComponents: .date)
                                .font(AjetoFont.body(15, weight: .medium))
                                .foregroundStyle(AjetoColor.ink)
                                .tint(AjetoColor.blue)
                        }
                    }

                    if editingProject != nil {
                        Section(title: "Status") {
                            Toggle(isOn: $isCompleted) {
                                Text(isCompleted ? "Afgerond" : "Nog bezig")
                                    .font(AjetoFont.body(15, weight: .semibold))
                                    .foregroundStyle(AjetoColor.ink)
                            }
                            .tint(AjetoColor.green)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(editingProject == nil ? "Nieuw project" : "Project bewerken")
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
            if let project = editingProject {
                name = project.name
                details = project.details
                isCompleted = project.isCompleted
                if let dl = project.deadline {
                    hasDeadline = true
                    deadline = dl
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            let project = Project(
                name: trimmedName,
                details: trimmedDetails,
                deadline: hasDeadline ? deadline : nil,
                isCompleted: false
            )
            project.household = Household.primary(in: context)
            context.insert(project)
        case .edit(let project):
            project.name = trimmedName
            project.details = trimmedDetails
            project.deadline = hasDeadline ? deadline : nil
            project.isCompleted = isCompleted
        }
        dismiss()
    }
}

private struct Section<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).ajEyebrow(AjetoColor.muted)
            VStack(spacing: 12) {
                content()
            }
            .ajCard(padding: 16)
        }
    }
}
