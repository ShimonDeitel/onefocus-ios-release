import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private var completedThings: [OneThing] { appModel.completedThings }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Streak summary
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.currentStreak)", label: "streak now")
                            MetricTile(value: "\(appModel.bestStreak)", label: "best streak")
                            MetricTile(value: "\(completedThings.count)", label: "total done")
                        }
                        .padding(.horizontal, 20)

                        if completedThings.isEmpty {
                            emptyState
                        } else {
                            completionInsights
                            historyWall
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 48))
                .foregroundStyle(Color.qmAccent.opacity(0.4))
            Text("No completed focuses yet.")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Set your first one thing and mark it done.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Completion insights

    private var completionInsights: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insights")
                .font(.headline)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    insightTile(
                        icon: "calendar.badge.checkmark",
                        value: completionRateThisMonth,
                        label: "this month"
                    )
                    insightTile(
                        icon: "clock",
                        value: averageDoneTime,
                        label: "avg done time"
                    )
                    insightTile(
                        icon: "chart.bar.fill",
                        value: mostActiveDay,
                        label: "top day"
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func insightTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.qmAccent)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - History wall

    private var historyWall: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Completed Focuses")
                .font(.headline)
                .padding(.horizontal, 20)

            LazyVStack(spacing: 10) {
                ForEach(completedThings, id: \.id) { thing in
                    historyRow(thing)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func historyRow(_ thing: OneThing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thing.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(thing.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let doneAt = thing.doneAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.qmCorrect)
                        Text(doneAt, format: .dateTime.hour().minute())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !thing.why.isEmpty {
                Text(thing.why)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .qmCard()
    }

    // MARK: - Computed insight values

    private var completionRateThisMonth: String {
        let cal = Calendar.current
        let now = Date()
        let thisMonth = completedThings.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysSoFar = cal.component(.day, from: now)
        guard daysSoFar > 0 else { return "—" }
        let rate = Int(Double(thisMonth.count) / Double(daysSoFar) * 100)
        return "\(rate)%"
    }

    private var averageDoneTime: String {
        let withTime = completedThings.compactMap { $0.doneAt }
        guard !withTime.isEmpty else { return "—" }
        let cal = Calendar.current
        let minutes = withTime.map { cal.component(.hour, from: $0) * 60 + cal.component(.minute, from: $0) }
        let avg = minutes.reduce(0, +) / minutes.count
        let h = avg / 60
        let m = avg % 60
        let ampm = h >= 12 ? "PM" : "AM"
        let displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h)
        return String(format: "%d:%02d %@", displayH, m, ampm)
    }

    private var mostActiveDay: String {
        guard !completedThings.isEmpty else { return "—" }
        let cal = Calendar.current
        var dayCounts: [Int: Int] = [:]
        for thing in completedThings {
            let weekday = cal.component(.weekday, from: thing.date)
            dayCounts[weekday, default: 0] += 1
        }
        guard let topWeekday = dayCounts.max(by: { $0.value < $1.value })?.key else { return "—" }
        let symbols = cal.shortWeekdaySymbols
        return symbols[topWeekday - 1]
    }
}
