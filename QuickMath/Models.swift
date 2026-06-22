import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class OneThing {
    var id: UUID
    var date: Date
    var title: String
    var why: String
    var done: Bool
    var doneAt: Date?

    init(date: Date = Date(), title: String, why: String = "") {
        self.id = UUID()
        self.date = date
        self.title = title
        self.why = why
        self.done = false
        self.doneAt = nil
    }
}

@Model
final class FocusStreak {
    var current: Int
    var best: Int
    var lastDoneDate: Date?

    init() {
        self.current = 0
        self.best = 0
        self.lastDoneDate = nil
    }
}

@Model
final class Prefs {
    var askHour: Int
    var theme: String

    init() {
        self.askHour = 9
        self.theme = "system"
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var todayThing: OneThing?
    @Published private(set) var completedThings: [OneThing] = []
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([OneThing.self, FocusStreak.self, Prefs.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    func reload() {
        let ctx = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let allThings = (try? ctx.fetch(FetchDescriptor<OneThing>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        todayThing = allThings.first(where: { $0.date >= today && $0.date < tomorrow })
        completedThings = allThings.filter { $0.done }.sorted { ($0.doneAt ?? $0.date) > ($1.doneAt ?? $1.date) }

        let streaks = (try? ctx.fetch(FetchDescriptor<FocusStreak>())) ?? []
        let s = streaks.first ?? {
            let ns = FocusStreak()
            ctx.insert(ns)
            return ns
        }()
        currentStreak = s.current
        bestStreak = s.best
    }

    func refresh() { reload() }

    // MARK: - Business Logic

    func setTodayThing(title: String, why: String = "") {
        let ctx = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        // Remove any existing today thing
        let existing = (try? ctx.fetch(FetchDescriptor<OneThing>())) ?? []
        for thing in existing where thing.date >= today && thing.date < tomorrow {
            ctx.delete(thing)
        }

        let newThing = OneThing(date: Date(), title: title, why: why)
        ctx.insert(newThing)
        try? ctx.save()
        reload()
        Haptics.tap()
    }

    func markDone() {
        guard let thing = todayThing, !thing.done else { return }
        thing.done = true
        thing.doneAt = Date()
        try? container.mainContext.save()
        updateStreak()
        reload()
        Haptics.success()
    }

    private func updateStreak() {
        let ctx = container.mainContext
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let streaks = (try? ctx.fetch(FetchDescriptor<FocusStreak>())) ?? []
        let s = streaks.first ?? {
            let ns = FocusStreak()
            ctx.insert(ns)
            return ns
        }()

        if let last = s.lastDoneDate {
            let lastDay = cal.startOfDay(for: last)
            let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                s.current += 1
            } else if diff > 1 {
                s.current = 1
            }
            // diff == 0 means same day, no change
        } else {
            s.current = 1
        }
        s.lastDoneDate = today
        if s.current > s.best { s.best = s.current }
        try? ctx.save()
    }

    func deleteAllData() {
        let ctx = container.mainContext
        let things = (try? ctx.fetch(FetchDescriptor<OneThing>())) ?? []
        for t in things { ctx.delete(t) }
        let streaks = (try? ctx.fetch(FetchDescriptor<FocusStreak>())) ?? []
        for s in streaks { ctx.delete(s) }
        let prefs = (try? ctx.fetch(FetchDescriptor<Prefs>())) ?? []
        for p in prefs { ctx.delete(p) }
        try? ctx.save()
        reload()
    }
}
