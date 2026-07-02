import SwiftUI
import SwiftData

struct ChoreDetailView: View {
    @Bindable var chore: Chore
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !chore.photos.isEmpty {
                    PhotoGalleryView(photos: chore.photos)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $chore.isDone) {
                        Label(chore.isDone ? "Klaar" : "Nog te doen",
                              systemImage: chore.isDone ? "checkmark.circle.fill" : "circle")
                    }
                    .tint(.green)

                    if let start = chore.scheduledStart {
                        Divider()
                        Label {
                            if let end = chore.scheduledEnd {
                                Text("\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                            } else {
                                Text(start.formatted(date: .abbreviated, time: .shortened))
                            }
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.subheadline)
                    }

                    if !chore.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Divider()
                        Text(chore.details)
                            .font(.body)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(chore.title.isEmpty ? "Klus" : chore.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bewerken") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ChoreEditView(mode: .edit(chore))
            }
        }
    }
}
