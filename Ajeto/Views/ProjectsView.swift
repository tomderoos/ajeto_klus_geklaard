import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.createdAt, order: .reverse) private var allProjects: [Project]
    /// Ongebruikt in de view zelf, maar door mee te queryen refresht de view
    /// zodra er een klus toegevoegd/gewijzigd wordt — anders zou
    /// `project.choreCount` pas na de volgende SwiftData-observer-tick
    /// updaten, wat 10+ seconden kan duren.
    @Query private var choresTrigger: [Chore]

    @State private var showingNew = false

    private var active: [Project] {
        allProjects.filter { !$0.isCompleted }
    }

    private var finished: [Project] {
        allProjects.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                if allProjects.isEmpty {
                    EmptyState { showingNew = true }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if !active.isEmpty {
                                Section(header: "Actief", projects: active)
                            }
                            if !finished.isEmpty {
                                Section(header: "Afgerond", projects: finished)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Projecten")
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
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
                NavigationStack { ProjectEditView(mode: .create) }
            }
        }
    }
}

private struct Section: View {
    let header: String
    let projects: [Project]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header).ajEyebrow(AjetoColor.muted).padding(.horizontal, 4)
            VStack(spacing: 10) {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectRow(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            icon
            VStack(alignment: .leading, spacing: 6) {
                Text(project.name.isEmpty ? "Zonder titel" : project.name)
                    .font(AjetoFont.display(17, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(project.isCompleted ? AjetoColor.muted : AjetoColor.ink)
                    .strikethrough(project.isCompleted)
                metaLine
            }
            Spacer(minLength: 0)
            if !project.uniqueAssignees.isEmpty {
                AvatarStack(people: project.uniqueAssignees, size: 22, maxVisible: 3)
            }
        }
        .ajCard(padding: 14)
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous)
                .fill(AjetoColor.sky)
            Image(systemName: project.isCompleted ? "checkmark.seal.fill" : "square.stack.3d.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AjetoColor.blue)
        }
        .frame(width: 48, height: 48)
    }

    private var metaLine: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle").font(.system(size: 10, weight: .semibold))
                Text("\(project.completedCount)/\(project.choreCount)")
            }
            if let deadline = project.deadline {
                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.system(size: 10, weight: .semibold))
                    Text(deadline.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .font(AjetoFont.body(11, weight: .medium))
        .foregroundStyle(AjetoColor.muted)
    }
}

private struct EmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 40)
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AjetoColor.sky)
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AjetoColor.blue)
            }
            .frame(width: 96, height: 96)
            VStack(spacing: 8) {
                Text("Nog geen projecten").ajTitle().multilineTextAlignment(.center)
                Text("Bundel klussen rond een doel, bv. \"Zolder opknappen\".")
                    .ajCaption()
                    .multilineTextAlignment(.center)
            }
            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    Text("Nieuw project").font(AjetoFont.body(14, weight: .bold))
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
