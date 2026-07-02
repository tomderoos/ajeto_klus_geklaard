import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ChoreEditView: View {
    enum Mode {
        case create
        case edit(Chore)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var details = ""
    @State private var hasSchedule = false
    @State private var scheduledDate = Calendar.current.startOfDay(for: .now)
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var endTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now

    @State private var newPhotoFilenames: [String] = []
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

    var body: some View {
        Form {
            Section("Klus") {
                TextField("Titel (bv. voordeur schilderen)", text: $title)
                TextField("Beschrijving", text: $details, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Planning") {
                Toggle("Inplannen", isOn: $hasSchedule)
                if hasSchedule {
                    DatePicker("Datum", selection: $scheduledDate, displayedComponents: .date)
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Eind", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
                }
            }

            Section("Foto's") {
                let existing = editingChore?.photos ?? []
                if !existing.isEmpty || !newPhotoFilenames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(existing) { photo in
                                PhotoThumb(filename: photo.filename) {
                                    removeExisting(photo)
                                }
                            }
                            ForEach(newPhotoFilenames, id: \.self) { filename in
                                PhotoThumb(filename: filename) {
                                    removeNew(filename)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 5, matching: .images) {
                    Label("Uit bibliotheek", systemImage: "photo.on.rectangle")
                }
                if cameraAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Foto maken", systemImage: "camera")
                    }
                }
            }
        }
        .navigationTitle(editingChore == nil ? "Nieuwe klus" : "Klus bewerken")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleer") {
                    for f in newPhotoFilenames { PhotoStorage.delete(f) }
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Bewaar", action: save)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onChange(of: pickerItems) { _, items in
            Task { await ingestPickerItems(items) }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                if let image, let filename = try? PhotoStorage.save(image) {
                    newPhotoFilenames.append(filename)
                }
            }
        }
        .onAppear(perform: loadFromExisting)
    }

    private func loadFromExisting() {
        guard !didLoad else { return }
        didLoad = true
        guard let chore = editingChore else { return }
        title = chore.title
        details = chore.details
        if let start = chore.scheduledStart {
            hasSchedule = true
            scheduledDate = Calendar.current.startOfDay(for: start)
            startTime = start
            endTime = chore.scheduledEnd ?? start.addingTimeInterval(3600)
        }
    }

    private func ingestPickerItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data),
               let filename = try? PhotoStorage.save(img) {
                await MainActor.run {
                    newPhotoFilenames.append(filename)
                }
            }
        }
        await MainActor.run { pickerItems.removeAll() }
    }

    private func removeExisting(_ photo: ChorePhoto) {
        PhotoStorage.delete(photo.filename)
        context.delete(photo)
    }

    private func removeNew(_ filename: String) {
        PhotoStorage.delete(filename)
        newPhotoFilenames.removeAll { $0 == filename }
    }

    private func save() {
        let chore: Chore
        if let existing = editingChore {
            chore = existing
        } else {
            chore = Chore()
            context.insert(chore)
        }
        chore.title = title.trimmingCharacters(in: .whitespaces)
        chore.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        if hasSchedule {
            chore.scheduledStart = combine(date: scheduledDate, time: startTime)
            chore.scheduledEnd = combine(date: scheduledDate, time: endTime)
        } else {
            chore.scheduledStart = nil
            chore.scheduledEnd = nil
        }
        for filename in newPhotoFilenames {
            let photo = ChorePhoto(filename: filename)
            context.insert(photo)
            chore.photos.append(photo)
        }
        newPhotoFilenames.removeAll()
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

private struct PhotoThumb: View {
    let filename: String
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = PhotoStorage.load(filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 80, height: 80)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .font(.title3)
            }
            .padding(4)
        }
    }
}
