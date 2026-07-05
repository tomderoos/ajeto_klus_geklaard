import SwiftUI
import SwiftData

struct ChoreDetailView: View {
    @Bindable var chore: Chore
    @State private var showingEdit = false
    @State private var showingShare = false
    @State private var shareURL: URL?

    var body: some View {
        ZStack {
            AjetoColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !chore.photos.isEmpty {
                        PhotoGalleryView(photos: chore.photos)
                            .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        StatusToggle(chore: chore)

                        if let room = chore.room {
                            InfoRow(icon: "square.grid.2x2", label: "Ruimte") {
                                HStack(spacing: 6) {
                                    Image(systemName: room.iconName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(room.name)
                                }
                            }
                        }

                        if let start = chore.scheduledStart {
                            InfoRow(icon: "calendar", label: "Planning") {
                                if let end = chore.scheduledEnd {
                                    Text("\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                                } else {
                                    Text(start.formatted(date: .abbreviated, time: .shortened))
                                }
                            }
                        }

                        if !chore.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Beschrijving").ajEyebrow(AjetoColor.muted)
                                Text(chore.details).ajBody()
                            }
                        }
                    }
                    .ajCard(padding: 18)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(chore.title.isEmpty ? "Klus" : chore.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AjetoColor.paper, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    if let url = try? ChoreExport.writeTempFile(for: chore) {
                        shareURL = url
                        showingShare = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AjetoColor.ink)
                }
                Button("Bewerken") { showingEdit = true }
                    .font(AjetoFont.body(15, weight: .semibold))
                    .foregroundStyle(AjetoColor.blue)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack { ChoreEditView(mode: .edit(chore)) }
        }
        .sheet(isPresented: $showingShare, onDismiss: {
            if let shareURL {
                try? FileManager.default.removeItem(at: shareURL)
            }
            shareURL = nil
        }) {
            if let shareURL {
                ActivityView(items: [shareURL])
            }
        }
    }
}

private struct StatusToggle: View {
    @Bindable var chore: Chore

    var body: some View {
        Button {
            chore.isDone.toggle()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(chore.isDone ? AjetoColor.green : AjetoColor.mint)
                    if chore.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AjetoColor.ink)
                    }
                }
                .frame(width: 30, height: 30)
                .overlay(
                    Circle().strokeBorder(chore.isDone ? .clear : AjetoColor.green.opacity(0.5), lineWidth: 1.5)
                )
                Text(chore.isDone ? "Klaar" : "Nog te doen")
                    .font(AjetoFont.display(15, weight: .semibold))
                    .foregroundStyle(AjetoColor.ink)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct InfoRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
            }
            .ajEyebrow(AjetoColor.muted)
            content()
                .font(AjetoFont.body(15, weight: .medium))
                .foregroundStyle(AjetoColor.ink)
        }
    }
}
