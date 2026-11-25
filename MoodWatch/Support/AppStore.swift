import Foundation
import SwiftUI
import Combine

/// Single source of truth for the app.
/// Health-derived history is demo data for now (see `SampleData`); moods, habit progress and
/// preferences are persisted locally, mirroring the original app's local-first stance.
@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var days: [DailyStress]
    @Published var moods: [MoodEntry]
    @Published var habits: [Habit]
    @Published var customLevelNames: [String]
    @Published var onboardingDone: Bool
    @Published var notifyStress: Bool
    @Published var notifyDigest: Bool
    @Published var useDemoData: Bool

    let lastUpdate: Date

    private let stateURL: URL
    private let health: HealthDataProvider

    init(health: HealthDataProvider = DemoHealthDataProvider()) {
        self.health = health
        let generated = health.dailyStress(days: 60)
        days = generated
        lastUpdate = Date()
        moods = SampleData.moods()
        habits = Habit.defaults()
        customLevelNames = StressLevel.allCases.map { $0.defaultName }
        onboardingDone = false
        notifyStress = true
        notifyDigest = false
        useDemoData = true

        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MoodWatch", isDirectory: true)
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        stateURL = dir.appendingPathComponent("state.json")

        load()
    }

    // MARK: - Derived values

    var today: DailyStress {
        days.last ?? DailyStress(date: Date(), hrv: 0, rhr: 0, index: 50, level: nil)
    }

    var yesterday: DailyStress? {
        guard days.count >= 2 else { return nil }
        return days[days.count - 2]
    }

    var curve: [HRVPoint] { health.intradayHRV(on: today) }

    var latestSampleTime: Date { curve.last?.time ?? lastUpdate }

    /// Trailing 30-day baseline used for the "近 30 天平均" label.
    var baselineHRV: Double {
        StressMath.mean(days.suffix(30).filter { !$0.isNoData && $0.hrv <= 180 }.map { $0.hrv })
    }

    var averageRHR: Double {
        StressMath.mean(days.suffix(30).map { $0.rhr })
    }

    var last7: [DailyStress] { Array(days.suffix(7)) }

    func name(for level: StressLevel) -> String {
        let idx = max(0, min(customLevelNames.count - 1, level.rawValue - 1))
        return customLevelNames[idx]
    }

    func rename(level: StressLevel, to name: String) {
        let idx = max(0, min(customLevelNames.count - 1, level.rawValue - 1))
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        customLevelNames[idx] = trimmed
        save()
    }

    /// Distribution of levels over the last `window` days.
    func distribution(window: Int) -> [(level: StressLevel, count: Int)] {
        let slice = days.suffix(window)
        return StressLevel.allCases.map { level in
            (level, slice.filter { $0.level == level }.count)
        }
    }

    var topMoodTag: String? {
        let counts = moods.flatMap { $0.tags }.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.max { $0.value < $1.value }?.key
    }

    // MARK: - Mutation

    func addMood(_ entry: MoodEntry) {
        moods.insert(entry, at: 0)
        save()
    }

    func deleteMood(_ entry: MoodEntry) {
        moods.removeAll { $0.id == entry.id }
        save()
    }

    func toggleHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].progress = habits[idx].isComplete ? 0 : habits[idx].goal
        save()
    }

    func advanceHabit(_ habit: Habit, by amount: Double) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].progress = min(habits[idx].goal, habits[idx].progress + amount)
        save()
    }

    func resetDemoData() {
        days = health.dailyStress(days: 60)
        moods = SampleData.moods()
        habits = Habit.defaults()
        save()
    }

    func clearAll() {
        moods = []
        habits = Habit.defaults()
        customLevelNames = StressLevel.allCases.map { $0.defaultName }
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var moods: [MoodEntry]
        var habits: [Habit]
        var names: [String]
        var onboardingDone: Bool
        var notifyStress: Bool
        var notifyDigest: Bool
    }

    private func load() {
        guard let data = try? Data(contentsOf: stateURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        moods = snap.moods
        habits = snap.habits
        customLevelNames = snap.names
        onboardingDone = snap.onboardingDone
        notifyStress = snap.notifyStress
        notifyDigest = snap.notifyDigest
    }

    func save() {
        let snap = Snapshot(
            moods: moods,
            habits: habits,
            names: customLevelNames,
            onboardingDone: onboardingDone,
            notifyStress: notifyStress,
            notifyDigest: notifyDigest
        )
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: stateURL, options: .atomic)
        }
    }
}
