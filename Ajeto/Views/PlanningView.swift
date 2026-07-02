import SwiftUI
import SwiftData

struct PlanningView: View {
    @Query(sort: \Chore.createdAt, order: .reverse) private var allChores: [Chore]

    private var scheduled: [Chore] {
        allChores
            .filter { $0.scheduledStart != nil }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            Group {
                let items = scheduled.filter { $0.scheduledStart != nil }
                if items.isEmpty {
                    ContentUnavailableView(
                        "Niets gepland",
                        systemImage: "calendar",
                        description: Text("Plan een klus in via de klussenlijst.")
                    )
                } else {
                    List {
                        let grouped = Dictionary(grouping: items) { chore in
                            Calendar.current.startOfDay(for: chore.scheduledStart ?? .now)
                        }
                        let days = grouped.keys.sorted()
                        ForEach(days, id: \.self) { day in
                            Section(header: Text(Self.dayHeader(day))) {
                                ForEach(grouped[day] ?? []) { chore in
                                    NavigationLink {
                                        ChoreDetailView(chore: chore)
                                    } label: {
                                        ScheduledRow(chore: chore)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Planning")
        }
    }

    private static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .full
        return f
    }()

    private static func dayHeader(_ date: Date) -> String {
        headerFormatter.string(from: date).capitalized
    }
}

private struct ScheduledRow: View {
    let chore: Chore

    var body: some View {
        HStack(spacing: 12) {
            if let start = chore.scheduledStart {
                VStack(alignment: .leading, spacing: 2) {
                    Text(start.formatted(date: .omitted, time: .shortened))
                    if let end = chore.scheduledEnd {
                        Text(end.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption.monospacedDigit())
                .frame(width: 56, alignment: .leading)
            }
            Text(chore.title.isEmpty ? "Zonder titel" : chore.title)
                .strikethrough(chore.isDone)
                .foregroundStyle(chore.isDone ? .secondary : .primary)
            Spacer()
            if chore.isDone {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
    }
}
