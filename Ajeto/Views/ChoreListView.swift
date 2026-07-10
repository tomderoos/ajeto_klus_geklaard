import SwiftUI
import SwiftData

struct ChoreListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Chore.createdAt, order: .reverse) private var allChores: [Chore]
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]

    @State private var selectedRoomID: PersistentIdentifier? = nil
    @State private var selectedProjectID: PersistentIdentifier? = nil
    @AppStorage("userName") private var userName: String = ""
    @State private var showingNameEditor = false
    @State private var showingNew = false
    @State private var showingRooms = false
    @State private var showingNewRoom = false
    @State private var showingPersons = false
    @State private var showingOnboarding = false
    @State private var bulkShare: BulkSharePayload?

    private var filteredChores: [Chore] {
        let base = allChores.filter { chore in
            if let selectedRoomID, chore.room?.persistentModelID != selectedRoomID {
                return false
            }
            if let selectedProjectID, chore.project?.persistentModelID != selectedProjectID {
                return false
            }
            return true
        }
        return base.sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone { return !lhs.isDone && rhs.isDone }
            switch (lhs.scheduledStart, rhs.scheduledStart) {
            case let (l?, r?): return l < r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.createdAt > rhs.createdAt
            }
        }
    }

    private var selectedRoomName: String? {
        guard let selectedRoomID else { return nil }
        return rooms.first { $0.persistentModelID == selectedRoomID }?.name
    }

    private var selectedProjectName: String? {
        guard let selectedProjectID else { return nil }
        return projects.first { $0.persistentModelID == selectedProjectID }?.name
    }

    private var emptyStateContext: String? {
        selectedProjectName ?? selectedRoomName
    }

    /// Klussen-tab title toont een tijdgebonden begroeting als de gebruiker
    /// een voornaam heeft ingevuld tijdens onboarding, anders de standaard
    /// "Klussen" label. Wordt op elke render opnieuw berekend zodat 'ie
    /// mee-verandert met de tijd van de dag.
    private var navigationTitle: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Klussen" }
        let hour = Calendar.current.component(.hour, from: .now)
        let salutation: String
        switch hour {
        case 5..<12:  salutation = "Goedemorgen"
        case 12..<18: salutation = "Goedemiddag"
        case 18..<23: salutation = "Goedenavond"
        default:      salutation = "Goedenacht"
        }
        return "\(salutation) \(trimmed)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    RoomFilterBar(
                        rooms: rooms,
                        selectedID: $selectedRoomID,
                        onAddRoom: { showingNewRoom = true }
                    )
                    if !projects.isEmpty {
                        ProjectFilterBar(
                            projects: projects,
                            selectedID: $selectedProjectID
                        )
                    }
                    if filteredChores.isEmpty {
                        EmptyState(context: emptyStateContext)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredChores) { chore in
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
            }
            .navigationTitle(navigationTitle)
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button {
                            startBulkShare()
                        } label: {
                            Label("Alle klussen delen (\(allChores.count))", systemImage: "square.and.arrow.up")
                        }
                        .disabled(allChores.isEmpty)

                        Button {
                            showingRooms = true
                        } label: {
                            Label("Ruimtes beheren", systemImage: "square.grid.2x2")
                        }

                        Button {
                            showingPersons = true
                        } label: {
                            Label("Personen beheren", systemImage: "person.2")
                        }

                        Button {
                            showingNameEditor = true
                        } label: {
                            Label("Naam wijzigen", systemImage: "person.text.rectangle")
                        }

                        Divider()

                        Button {
                            showingOnboarding = true
                        } label: {
                            Label("Rondleiding", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AjetoColor.ink)
                            .frame(width: 34, height: 34)
                            .background(AjetoColor.surface, in: Circle())
                            .overlay(Circle().stroke(AjetoColor.border, lineWidth: 1))
                    }
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
                    ChoreEditView(mode: .create(prefilledRoomID: selectedRoomID, prefilledProjectID: selectedProjectID))
                }
            }
            .sheet(isPresented: $showingRooms) {
                RoomsSheetView()
            }
            .sheet(isPresented: $showingNewRoom) {
                NavigationStack {
                    RoomEditView(mode: .create(nextSortOrder: (rooms.last?.sortOrder ?? -1) + 1))
                }
            }
            .sheet(item: $bulkShare) { payload in
                BulkShareSheet(payload: payload)
            }
            .sheet(isPresented: $showingPersons) {
                PersonsSheetView()
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .sheet(isPresented: $showingNameEditor) {
                NameEditorSheet()
                    .presentationDetents([.medium])
            }
        }
    }

    private func startBulkShare() {
        guard !allChores.isEmpty else { return }
        let now = Date.now
        let dateString = Self.bulkFilenameDate(from: now)
        let filename = "Ajeto klussen \(dateString)"
        do {
            let url = try ChoreExport.writeTempFile(for: allChores, filename: filename)
            bulkShare = BulkSharePayload(url: url, count: allChores.count, exportedAt: now)
        } catch {
            // Silently negeren — sheet gaat gewoon niet open.
        }
    }

    private static func bulkFilenameDate(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH.mm"
        return f.string(from: date)
    }

    private func delete(_ chore: Chore) {
        NotificationService.cancel(for: chore)
        for photo in chore.photosList {
            if !photo.filename.isEmpty {
                PhotoStorage.delete(photo.filename)
            }
            context.delete(photo)
        }
        context.delete(chore)
    }
}

private struct RoomFilterBar: View {
    let rooms: [Room]
    @Binding var selectedID: PersistentIdentifier?
    let onAddRoom: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !rooms.isEmpty {
                    Chip(label: "Alle", icon: nil, selected: selectedID == nil) {
                        selectedID = nil
                    }
                    ForEach(rooms) { room in
                        Chip(label: room.name, icon: room.iconName, selected: selectedID == room.persistentModelID) {
                            selectedID = (selectedID == room.persistentModelID) ? nil : room.persistentModelID
                        }
                    }
                }
                AddRoomChip(action: onAddRoom)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

private struct ProjectFilterBar: View {
    let projects: [Project]
    @Binding var selectedID: PersistentIdentifier?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(
                    label: "Alle projecten",
                    icon: "square.stack.3d.up",
                    selected: selectedID == nil,
                    accent: AjetoColor.blue
                ) {
                    selectedID = nil
                }
                ForEach(projects) { project in
                    Chip(
                        label: project.name.isEmpty ? "Zonder titel" : project.name,
                        icon: project.isCompleted ? "checkmark.seal" : nil,
                        selected: selectedID == project.persistentModelID,
                        accent: AjetoColor.blue
                    ) {
                        selectedID = (selectedID == project.persistentModelID) ? nil : project.persistentModelID
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

private struct AddRoomChip: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("Nieuwe ruimte")
                    .font(AjetoFont.body(13, weight: .semibold))
            }
            .foregroundStyle(AjetoColor.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AjetoColor.sky, in: Capsule())
            .overlay(
                Capsule().stroke(AjetoColor.blue.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct Chip: View {
    let label: String
    let icon: String?
    let selected: Bool
    var accent: Color = AjetoColor.green
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                }
                Text(label).font(AjetoFont.body(13, weight: .semibold))
            }
            .foregroundStyle(selected ? (accent == AjetoColor.green ? AjetoColor.ink : .white) : AjetoColor.muted)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? accent : AjetoColor.surface, in: Capsule())
            .overlay(
                Capsule().stroke(selected ? .clear : AjetoColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyState: View {
    let context: String?

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 40)
            AjetoBrandIcon(size: 96, glow: true)
            VStack(spacing: 8) {
                Text(context == nil ? "Nog geen klussen" : "Niks te doen in \(context!)")
                    .ajTitle()
                    .multilineTextAlignment(.center)
                Text("Tik op + om een klus toe te voegen.")
                    .ajCaption()
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
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
                HStack(spacing: 8) {
                    if let room = chore.room {
                        RoomBadge(room: room, compact: true)
                    }
                    if let start = chore.scheduledStart {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .semibold))
                            Text(start.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(AjetoFont.body(11, weight: .medium))
                        .foregroundStyle(AjetoColor.muted)
                    }
                    if chore.recurrence != .none {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9, weight: .semibold))
                            Text(chore.recurrence.shortLabel)
                                .font(AjetoFont.body(10, weight: .semibold))
                        }
                        .foregroundStyle(AjetoColor.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AjetoColor.sky, in: Capsule())
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                if chore.isDone {
                    DoneBadge()
                }
                if let assignees = chore.assignees, !assignees.isEmpty {
                    AvatarStack(people: assignees, size: 22, maxVisible: 3)
                }
            }
        }
        .ajCard(padding: 14)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = chore.photosList.first?.loadImage() {
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

/// Compacte sheet om je voornaam achteraf te wijzigen. Update de @AppStorage
/// waarde die de begroeting voedt, én hernoemt de bijbehorende Person zodat
/// bestaande klus-toewijzingen behouden blijven.
private struct NameEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("userName") private var userName: String = ""

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(AjetoColor.mint)
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(AjetoColor.greenInk)
                    }
                    .frame(width: 72, height: 72)

                    VStack(spacing: 6) {
                        Text("Jouw voornaam")
                            .font(AjetoFont.display(20, weight: .bold))
                            .tracking(-0.3)
                            .foregroundStyle(AjetoColor.ink)
                        Text("Wordt gebruikt voor de begroeting en om klussen aan jezelf toe te wijzen.")
                            .ajCaption()
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    TextField("Voornaam", text: $draft)
                        .font(AjetoFont.display(18, weight: .semibold))
                        .foregroundStyle(AjetoColor.ink)
                        .tint(AjetoColor.green)
                        .textInputAutocapitalization(.words)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AjetoColor.surface, in: Capsule())
                        .overlay(Capsule().stroke(AjetoColor.border, lineWidth: 1))
                        .focused($focused)
                        .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 32)
            }
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
                draft = userName
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    focused = true
                }
            }
        }
    }

    private func save() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Bestaande "ik"-Person hernoemen als naam-match klopte, anders nieuw
        // maken. Hierdoor blijven eerdere klus-toewijzingen intact.
        let old = userName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !old.isEmpty,
           let all = try? context.fetch(FetchDescriptor<Person>()),
           let existing = all.first(where: { $0.name.lowercased() == old }) {
            existing.name = trimmed
            try? context.save()
        } else {
            _ = Person.findOrCreate(
                name: trimmed,
                in: context,
                household: Household.primary(in: context)
            )
        }
        userName = trimmed
        dismiss()
    }
}
