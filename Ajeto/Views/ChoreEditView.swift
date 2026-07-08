import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ChoreEditView: View {
    enum Mode {
        case create(prefilledRoomID: PersistentIdentifier?, prefilledProjectID: PersistentIdentifier? = nil)
        case edit(Chore)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.sortOrder) private var rooms: [Room]
    @Query(sort: \Person.sortOrder) private var persons: [Person]
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]

    @State private var title = ""
    @State private var details = ""
    @State private var selectedRoomID: PersistentIdentifier?
    @State private var selectedProjectID: PersistentIdentifier?
    @State private var selectedPersonIDs: Set<PersistentIdentifier> = []
    @State private var hasSchedule = false
    @State private var scheduledDate = Calendar.current.startOfDay(for: .now)
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var endTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now

    @State private var newPhotoDatas: [Data] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var didLoad = false

    private var editingChore: Chore? {
        if case .edit(let c) = mode { return c }
        return nil
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Section(title: "Klus") {
                        Field(placeholder: "Titel (bv. voordeur schilderen)", text: $title)
                        MultilineField(placeholder: "Beschrijving", text: $details)
                    }

                    if !rooms.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ruimte").ajEyebrow(AjetoColor.muted)
                            RoomPicker(rooms: rooms, selectedID: $selectedRoomID)
                        }
                    }

                    if !projects.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Project").ajEyebrow(AjetoColor.muted)
                            ProjectPicker(projects: projects, selectedID: $selectedProjectID)
                        }
                    }

                    if !persons.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Wie doet dit?").ajEyebrow(AjetoColor.muted)
                            PersonMultiPicker(persons: persons, selectedIDs: $selectedPersonIDs)
                        }
                    }

                    Section(title: "Planning") {
                        Toggle(isOn: $hasSchedule.animation(.easeInOut(duration: 0.2))) {
                            Text("Inplannen")
                                .font(AjetoFont.body(15, weight: .semibold))
                                .foregroundStyle(AjetoColor.ink)
                        }
                        .tint(AjetoColor.green)
                        if hasSchedule {
                            Divider().overlay(AjetoColor.border)
                            DatePickerRow(label: "Datum", selection: $scheduledDate, components: .date)
                            Divider().overlay(AjetoColor.border)
                            DatePickerRow(label: "Start", selection: $startTime, components: .hourAndMinute)
                            Divider().overlay(AjetoColor.border)
                            DatePickerRow(label: "Eind", selection: $endTime, components: .hourAndMinute, range: startTime...)
                        }
                    }

                    Section(title: "Foto's") {
                        let existing = editingChore?.photosList ?? []
                        if !existing.isEmpty || !newPhotoDatas.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(existing) { photo in
                                        PhotoThumb(image: photo.loadImage()) {
                                            removeExisting(photo)
                                        }
                                    }
                                    ForEach(Array(newPhotoDatas.enumerated()), id: \.offset) { index, data in
                                        PhotoThumb(image: UIImage(data: data)) {
                                            newPhotoDatas.remove(at: index)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        HStack(spacing: 10) {
                            PhotosPicker(selection: $pickerItems, maxSelectionCount: 5, matching: .images) {
                                ActionChip(icon: "photo.on.rectangle", label: "Bibliotheek", tint: AjetoColor.blue, bg: AjetoColor.sky)
                            }
                            if cameraAvailable {
                                Button {
                                    showingCamera = true
                                } label: {
                                    ActionChip(icon: "camera", label: "Camera", tint: AjetoColor.greenInk, bg: AjetoColor.mint)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(editingChore == nil ? "Nieuwe klus" : "Klus bewerken")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AjetoColor.paper, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleer") {
                    newPhotoDatas.removeAll()
                    dismiss()
                }
                .font(AjetoFont.body(15, weight: .medium))
                .foregroundStyle(AjetoColor.muted)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Bewaar", action: save)
                    .font(AjetoFont.body(15, weight: .bold))
                    .foregroundStyle(canSave ? AjetoColor.blue : AjetoColor.faint)
                    .disabled(!canSave)
            }
        }
        .onChange(of: pickerItems) { _, items in
            Task { await ingestPickerItems(items) }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                if let image, let data = image.jpegData(compressionQuality: 0.85) {
                    newPhotoDatas.append(data)
                }
            }
        }
        .onAppear(perform: loadFromExisting)
    }

    private func loadFromExisting() {
        guard !didLoad else { return }
        didLoad = true
        switch mode {
        case .create(let prefilledRoomID, let prefilledProjectID):
            selectedRoomID = prefilledRoomID
            selectedProjectID = prefilledProjectID
        case .edit(let chore):
            title = chore.title
            details = chore.details
            selectedRoomID = chore.room?.persistentModelID
            selectedProjectID = chore.project?.persistentModelID
            selectedPersonIDs = Set((chore.assignees ?? []).map(\.persistentModelID))
            if let start = chore.scheduledStart {
                hasSchedule = true
                scheduledDate = Calendar.current.startOfDay(for: start)
                startTime = start
                endTime = chore.scheduledEnd ?? start.addingTimeInterval(3600)
            }
        }
    }

    private func ingestPickerItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data),
               let jpeg = img.jpegData(compressionQuality: 0.85) {
                await MainActor.run {
                    newPhotoDatas.append(jpeg)
                }
            }
        }
        await MainActor.run { pickerItems.removeAll() }
    }

    private func removeExisting(_ photo: ChorePhoto) {
        if !photo.filename.isEmpty {
            PhotoStorage.delete(photo.filename)
        }
        context.delete(photo)
    }

    private func save() {
        let chore: Chore
        if let existing = editingChore {
            chore = existing
        } else {
            chore = Chore()
            chore.household = Household.primary(in: context)
            context.insert(chore)
        }
        chore.title = title.trimmingCharacters(in: .whitespaces)
        chore.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        chore.room = rooms.first { $0.persistentModelID == selectedRoomID }
        chore.project = projects.first { $0.persistentModelID == selectedProjectID }
        chore.assignees = persons.filter { selectedPersonIDs.contains($0.persistentModelID) }
        if hasSchedule {
            chore.scheduledStart = combine(date: scheduledDate, time: startTime)
            chore.scheduledEnd = combine(date: scheduledDate, time: endTime)
        } else {
            chore.scheduledStart = nil
            chore.scheduledEnd = nil
        }
        for data in newPhotoDatas {
            let photo = ChorePhoto(jpegData: data)
            context.insert(photo)
            if chore.photos == nil { chore.photos = [] }
            chore.photos?.append(photo)
        }
        newPhotoDatas.removeAll()
        dismiss()
    }

    private func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = d.year
        merged.month = d.month
        merged.day = d.day
        merged.hour = t.hour
        merged.minute = t.minute
        return cal.date(from: merged) ?? date
    }
}

// MARK: - Building blocks

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

private struct ProjectPicker: View {
    let projects: [Project]
    @Binding var selectedID: PersistentIdentifier?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(label: "Geen", icon: nil, selected: selectedID == nil) {
                    selectedID = nil
                }
                ForEach(projects) { project in
                    Chip(
                        label: project.name.isEmpty ? "Zonder titel" : project.name,
                        icon: project.isCompleted ? "checkmark.seal" : "square.stack.3d.up",
                        selected: selectedID == project.persistentModelID
                    ) {
                        selectedID = project.persistentModelID
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct PersonMultiPicker: View {
    let persons: [Person]
    @Binding var selectedIDs: Set<PersistentIdentifier>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(persons) { person in
                    let selected = selectedIDs.contains(person.persistentModelID)
                    Button {
                        if selected {
                            selectedIDs.remove(person.persistentModelID)
                        } else {
                            selectedIDs.insert(person.persistentModelID)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            PersonAvatar(person: person, size: 22)
                            Text(person.name)
                                .font(AjetoFont.body(13, weight: .semibold))
                        }
                        .foregroundStyle(selected ? AjetoColor.ink : AjetoColor.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selected ? AjetoColor.green : AjetoColor.surface, in: Capsule())
                        .overlay(
                            Capsule().stroke(selected ? .clear : AjetoColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct RoomPicker: View {
    let rooms: [Room]
    @Binding var selectedID: PersistentIdentifier?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(label: "Geen", icon: nil, selected: selectedID == nil) {
                    selectedID = nil
                }
                ForEach(rooms) { room in
                    Chip(label: room.name, icon: room.iconName, selected: selectedID == room.persistentModelID) {
                        selectedID = room.persistentModelID
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct Chip: View {
    let label: String
    let icon: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                }
                Text(label).font(AjetoFont.body(13, weight: .semibold))
            }
            .foregroundStyle(selected ? AjetoColor.ink : AjetoColor.muted)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AjetoColor.green : AjetoColor.surface, in: Capsule())
            .overlay(
                Capsule().stroke(selected ? .clear : AjetoColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct Field: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AjetoFont.body(15, weight: .medium))
            .foregroundStyle(AjetoColor.ink)
            .tint(AjetoColor.blue)
    }
}

private struct MultilineField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(AjetoFont.body(15, weight: .regular))
                    .foregroundStyle(AjetoColor.faint)
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            TextField("", text: $text, axis: .vertical)
                .lineLimit(3...8)
                .font(AjetoFont.body(15, weight: .regular))
                .foregroundStyle(AjetoColor.ink)
                .tint(AjetoColor.blue)
        }
    }
}

private struct DatePickerRow: View {
    let label: String
    @Binding var selection: Date
    let components: DatePicker.Components
    var range: PartialRangeFrom<Date>? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(AjetoFont.body(15, weight: .medium))
                .foregroundStyle(AjetoColor.ink)
            Spacer()
            if let range {
                DatePicker(label, selection: $selection, in: range, displayedComponents: components)
                    .labelsHidden()
                    .tint(AjetoColor.blue)
            } else {
                DatePicker(label, selection: $selection, displayedComponents: components)
                    .labelsHidden()
                    .tint(AjetoColor.blue)
            }
        }
    }
}

private struct ActionChip: View {
    let icon: String
    let label: String
    let tint: Color
    let bg: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(AjetoFont.body(14, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bg, in: Capsule())
    }
}

private struct PhotoThumb: View {
    let image: UIImage?
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous)
                    .fill(AjetoColor.mint)
                    .frame(width: 88, height: 88)
            }
            Button(action: onDelete) {
                ZStack {
                    Circle().fill(AjetoColor.ink)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 22, height: 22)
            }
            .padding(6)
        }
    }
}
