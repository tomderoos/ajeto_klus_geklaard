import SwiftUI
import SwiftData

struct PlanningView: View {
    @Query(sort: \Chore.createdAt, order: .reverse) private var allChores: [Chore]
    @Query(sort: \Person.sortOrder) private var persons: [Person]

    @State private var selectedPersonID: PersistentIdentifier?

    private var scheduled: [Chore] {
        allChores
            .filter { $0.scheduledStart != nil }
            .filter { chore in
                guard let selectedPersonID else { return true }
                return (chore.assignees ?? []).contains { $0.persistentModelID == selectedPersonID }
            }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    private var grouped: [(Date, [Chore])] {
        let dict = Dictionary(grouping: scheduled) { chore in
            Calendar.current.startOfDay(for: chore.scheduledStart ?? .now)
        }
        return dict.keys.sorted().map { ($0, dict[$0] ?? []) }
    }

    private var selectedPersonName: String? {
        guard let selectedPersonID else { return nil }
        return persons.first { $0.persistentModelID == selectedPersonID }?.name
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    if !persons.isEmpty {
                        PersonFilterBar(persons: persons, selectedID: $selectedPersonID)
                    }
                    if scheduled.isEmpty {
                        EmptyPlanning(personName: selectedPersonName)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(grouped, id: \.0) { day, chores in
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(Self.headerText(for: day))
                                            .ajEyebrow(AjetoColor.muted)
                                            .padding(.horizontal, 4)
                                        VStack(spacing: 10) {
                                            ForEach(chores) { chore in
                                                NavigationLink {
                                                    ChoreDetailView(chore: chore)
                                                } label: {
                                                    ScheduledRow(chore: chore)
                                                }
                                                .buttonStyle(.plain)
                                            }
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
            .navigationTitle("Planning")
            .toolbarBackground(AjetoColor.paper, for: .navigationBar)
        }
    }

    private static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .full
        return f
    }()

    private static func headerText(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Vandaag" }
        if cal.isDateInTomorrow(date) { return "Morgen" }
        return headerFormatter.string(from: date).capitalized
    }
}

private struct PersonFilterBar: View {
    let persons: [Person]
    @Binding var selectedID: PersistentIdentifier?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedID = nil
                } label: {
                    Text("Iedereen")
                        .font(AjetoFont.body(13, weight: .semibold))
                        .foregroundStyle(selectedID == nil ? AjetoColor.ink : AjetoColor.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedID == nil ? AjetoColor.green : AjetoColor.surface, in: Capsule())
                        .overlay(
                            Capsule().stroke(selectedID == nil ? .clear : AjetoColor.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                ForEach(persons) { person in
                    let isSelected = selectedID == person.persistentModelID
                    Button {
                        selectedID = isSelected ? nil : person.persistentModelID
                    } label: {
                        HStack(spacing: 6) {
                            PersonAvatar(person: person, size: 20)
                            Text(person.name)
                                .font(AjetoFont.body(13, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? .white : AjetoColor.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color(hex: person.colorHex) : AjetoColor.surface, in: Capsule())
                        .overlay(
                            Capsule().stroke(isSelected ? .clear : AjetoColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

private struct EmptyPlanning: View {
    let personName: String?

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 40)
            AjetoBrandIcon(size: 96, glow: true)
            VStack(spacing: 8) {
                Text(personName == nil ? "Niets gepland" : "Niks gepland voor \(personName!)")
                    .ajTitle()
                    .multilineTextAlignment(.center)
                Text("Plan een klus in via de klussenlijst.")
                    .ajCaption()
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}

private struct ScheduledRow: View {
    let chore: Chore

    var body: some View {
        HStack(spacing: 14) {
            timeBlock
            VStack(alignment: .leading, spacing: 6) {
                Text(chore.title.isEmpty ? "Zonder titel" : chore.title)
                    .font(AjetoFont.display(16, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(chore.isDone ? AjetoColor.muted : AjetoColor.ink)
                    .strikethrough(chore.isDone)
                if let room = chore.room {
                    RoomBadge(room: room, compact: true)
                } else if !chore.details.isEmpty {
                    Text(chore.details)
                        .font(AjetoFont.body(13, weight: .regular))
                        .foregroundStyle(AjetoColor.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                if chore.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AjetoColor.green)
                }
                if let assignees = chore.assignees, !assignees.isEmpty {
                    AvatarStack(people: assignees, size: 20, maxVisible: 3)
                }
            }
        }
        .ajCard(padding: 12)
    }

    private var timeBlock: some View {
        VStack(alignment: .center, spacing: 2) {
            if let start = chore.scheduledStart {
                Text(start.formatted(date: .omitted, time: .shortened))
                    .font(AjetoFont.body(13, weight: .bold).monospacedDigit())
                    .foregroundStyle(AjetoColor.ink)
            }
            if let end = chore.scheduledEnd {
                Text(end.formatted(date: .omitted, time: .shortened))
                    .font(AjetoFont.body(11, weight: .medium).monospacedDigit())
                    .foregroundStyle(AjetoColor.muted)
            }
        }
        .frame(width: 56, height: 56)
        .background(AjetoColor.mint, in: RoundedRectangle(cornerRadius: AjetoRadius.sm, style: .continuous))
    }
}
