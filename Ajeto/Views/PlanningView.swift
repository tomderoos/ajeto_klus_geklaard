import SwiftUI
import SwiftData

struct PlanningView: View {
    @Query(sort: \Chore.createdAt, order: .reverse) private var allChores: [Chore]

    private var scheduled: [Chore] {
        allChores
            .filter { $0.scheduledStart != nil }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    private var grouped: [(Date, [Chore])] {
        let dict = Dictionary(grouping: scheduled) { chore in
            Calendar.current.startOfDay(for: chore.scheduledStart ?? .now)
        }
        return dict.keys.sorted().map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AjetoColor.paper.ignoresSafeArea()
                if scheduled.isEmpty {
                    EmptyPlanning()
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

private struct EmptyPlanning: View {
    var body: some View {
        VStack(spacing: 22) {
            AjetoBrandIcon(size: 96, glow: true)
            VStack(spacing: 8) {
                Text("Niets gepland").ajTitle()
                Text("Plan een klus in via de klussenlijst.")
                    .ajCaption()
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

private struct ScheduledRow: View {
    let chore: Chore

    var body: some View {
        HStack(spacing: 14) {
            timeBlock
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title.isEmpty ? "Zonder titel" : chore.title)
                    .font(AjetoFont.display(16, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(chore.isDone ? AjetoColor.muted : AjetoColor.ink)
                    .strikethrough(chore.isDone)
                if !chore.details.isEmpty {
                    Text(chore.details)
                        .font(AjetoFont.body(13, weight: .regular))
                        .foregroundStyle(AjetoColor.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if chore.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AjetoColor.green)
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
