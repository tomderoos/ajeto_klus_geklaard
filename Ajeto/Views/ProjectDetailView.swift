import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    /// Zelfde reden als in ProjectsView: forceer re-render bij Chore-inserts
    /// zodat het klussenlijstje meteen updatet.
    @Query private var choresTrigger: [Chore]

    @State private var showingEdit = false
    @State private var showingNewChore = false

    private var chores: [Chore] {
        (project.chores ?? []).sorted { lhs, rhs in
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
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderCard(project: project)
                    if !project.uniqueAssignees.isEmpty {
                        TeamCard(persons: project.uniqueAssignees)
                    }
                    ChoresList(chores: chores, onNew: { showingNewChore = true })
                }
                .padding(16)
            }
        }
        .navigationTitle(project.name.isEmpty ? "Project" : project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AjetoColor.paper, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bewerken") { showingEdit = true }
                    .font(AjetoFont.body(15, weight: .semibold))
                    .foregroundStyle(AjetoColor.blue)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack { ProjectEditView(mode: .edit(project)) }
        }
        .sheet(isPresented: $showingNewChore) {
            NavigationStack {
                ChoreEditView(mode: .create(prefilledRoomID: nil, prefilledProjectID: project.persistentModelID))
            }
        }
    }
}

private struct HeaderCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(project.isCompleted ? "AFGEROND" : "ACTIEF")
                    .ajEyebrow(project.isCompleted ? AjetoColor.muted : AjetoColor.blue)
                Spacer()
                if let deadline = project.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.system(size: 11, weight: .semibold))
                        Text(deadline.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(AjetoFont.body(12, weight: .semibold))
                    .foregroundStyle(AjetoColor.muted)
                }
            }
            if !project.details.isEmpty {
                Text(project.details).ajBody()
            }
            Progress(project: project)
        }
        .ajCard(padding: 16)
    }
}

private struct Progress: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(project.completedCount) van \(project.choreCount) klaar")
                    .font(AjetoFont.body(13, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                Spacer()
                Text("\(percent)%")
                    .font(AjetoFont.body(13, weight: .bold).monospacedDigit())
                    .foregroundStyle(AjetoColor.muted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AjetoColor.mint)
                    Capsule().fill(AjetoColor.green)
                        .frame(width: geo.size.width * CGFloat(percent) / 100)
                }
            }
            .frame(height: 8)
        }
    }

    private var percent: Int {
        guard project.choreCount > 0 else { return 0 }
        return Int(Double(project.completedCount) / Double(project.choreCount) * 100)
    }
}

private struct TeamCard: View {
    let persons: [Person]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "person.2").font(.system(size: 11, weight: .semibold))
                Text("Teamleden")
            }
            .ajEyebrow(AjetoColor.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(persons) { person in
                        VStack(spacing: 6) {
                            PersonAvatar(person: person, size: 44)
                            Text(person.name)
                                .font(AjetoFont.body(11, weight: .semibold))
                                .foregroundStyle(AjetoColor.ink)
                                .lineLimit(1)
                        }
                        .frame(minWidth: 56)
                    }
                }
            }
        }
    }
}

private struct ChoresList: View {
    let chores: [Chore]
    let onNew: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Klussen (\(chores.count))").ajEyebrow(AjetoColor.muted)
                Spacer()
                Button(action: onNew) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                        Text("Nieuw").font(AjetoFont.body(12, weight: .bold))
                    }
                    .foregroundStyle(AjetoColor.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AjetoColor.sky, in: Capsule())
                }
            }
            if chores.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.title2).foregroundStyle(AjetoColor.faint)
                    Text("Nog geen klussen in dit project.")
                        .ajCaption()
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .ajCard(padding: 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(chores) { chore in
                        NavigationLink {
                            ChoreDetailView(chore: chore)
                        } label: {
                            ProjectChoreRow(chore: chore)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct ProjectChoreRow: View {
    let chore: Chore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: chore.isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(chore.isDone ? AjetoColor.green : AjetoColor.faint)
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title.isEmpty ? "Zonder titel" : chore.title)
                    .font(AjetoFont.display(15, weight: .semibold))
                    .foregroundStyle(chore.isDone ? AjetoColor.muted : AjetoColor.ink)
                    .strikethrough(chore.isDone)
                if let room = chore.room {
                    RoomBadge(room: room, compact: true)
                }
            }
            Spacer(minLength: 0)
            if let assignees = chore.assignees, !assignees.isEmpty {
                AvatarStack(people: assignees, size: 20, maxVisible: 3)
            }
        }
        .ajCard(padding: 12)
    }
}
