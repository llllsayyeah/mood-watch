import Foundation

// MARK: - Actions whose effect on stress can be compared

enum ActionTag: String, CaseIterable, Identifiable {
    case sleep7h
    case exercise20
    case sunbath20
    case meditation
    case caffeineHigh
    case lateBed
    case steps10k
    case water2000

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep7h: return "睡够 7 小时"
        case .exercise20: return "20 分钟以上运动"
        case .sunbath20: return "晨间晒太阳 20 分钟"
        case .meditation: return "有冥想记录"
        case .caffeineHigh: return "咖啡因 > 100mg"
        case .lateBed: return "晚于 01:00 睡觉"
        case .steps10k: return "10000+ 步"
        case .water2000: return "喝够 2000ml"
        }
    }

    var emoji: String {
        switch self {
        case .sleep7h: return "🌙"
        case .exercise20: return "🏃"
        case .sunbath20: return "🌞"
        case .meditation: return "🧘"
        case .caffeineHigh: return "☕️"
        case .lateBed: return "🛏"
        case .steps10k: return "👟"
        case .water2000: return "💧"
        }
    }
}

// MARK: - Deterministic per-day action tags

/// Demo history: which actions happened on a given day.
///
/// The probabilities lean the way real HRV data usually does — better sleep and more
/// daylight on calm days, more caffeine and later bedtimes on strained days — so the
/// comparison screen has something honest to show. Deterministic: same day, same tags.
enum ActionTags {
    static func set(for day: DailyStress) -> Set<ActionTag> {
        guard day.level != nil else { return [] }
        var strain = day.index / 100.0
        strain = min(1, max(0, strain))

        var result: Set<ActionTag> = []
        for tag in ActionTag.allCases where unit(day.date, tag) < probability(tag, strain: strain) {
            result.insert(tag)
        }
        return result
    }

    private static func probability(_ tag: ActionTag, strain: Double) -> Double {
        switch tag {
        case .sleep7h: return 0.72 - 0.55 * strain
        case .exercise20: return 0.58 - 0.22 * strain
        case .sunbath20: return 0.50 - 0.18 * strain
        case .meditation: return 0.34 - 0.10 * strain
        case .caffeineHigh: return 0.22 + 0.48 * strain
        case .lateBed: return 0.14 + 0.52 * strain
        case .steps10k: return 0.62 - 0.30 * strain
        case .water2000: return 0.55 - 0.16 * strain
        }
    }

    /// Stable pseudo-random value in 0..<1 for a (day, tag) pair.
    private static func unit(_ date: Date, _ tag: ActionTag) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        let dayNumber = UInt64(Int(date.timeIntervalSince1970 / 86_400))
        for byte in tag.rawValue.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001b3
        }
        hash = (hash ^ dayNumber) &* 0x100000001b3
        hash ^= hash >> 33
        return Double(hash % 1_000) / 1_000.0
    }
}

// MARK: - Comparison result

struct ActionComparison: Identifiable {
    let id: String
    let tag: ActionTag
    let matchingDays: Int
    let otherDays: Int
    let avgIndexMatching: Double
    let avgIndexOthers: Double
    let avgHrvMatching: Double
    let avgHrvOthers: Double
    let avgRhrMatching: Double
    let avgRhrOthers: Double

    init(tag: ActionTag, matching: [DailyStress], others: [DailyStress]) {
        self.id = tag.rawValue
        self.tag = tag
        self.matchingDays = matching.count
        self.otherDays = others.count
        self.avgIndexMatching = StressMath.mean(matching.map { $0.index })
        self.avgIndexOthers = StressMath.mean(others.map { $0.index })
        self.avgHrvMatching = StressMath.mean(matching.map { $0.hrv })
        self.avgHrvOthers = StressMath.mean(others.map { $0.hrv })
        self.avgRhrMatching = StressMath.mean(matching.map { $0.rhr })
        self.avgRhrOthers = StressMath.mean(others.map { $0.rhr })
    }

    var indexDelta: Double { avgIndexMatching - avgIndexOthers }
    var hrvDelta: Double { avgHrvMatching - avgHrvOthers }
    var rhrDelta: Double { avgRhrMatching - avgRhrOthers }

    var hasEnoughData: Bool { matchingDays >= 5 && otherDays >= 5 }

    /// Positive means this action goes with *lower* stress.
    var isPositive: Bool { hasEnoughData && indexDelta < -1 }
    var isNegative: Bool { hasEnoughData && indexDelta > 1 }
    var isNeutral: Bool { !isPositive && !isNegative }

    var impactLevel: String {
        let magnitude = abs(indexDelta)
        if magnitude < 4 { return "小" }
        if magnitude < 8 { return "中" }
        return "大"
    }

    /// Difference in stress index points against the other days.
    /// The index is a 0–100 score, so points are used rather than a relative percentage.
    var percentText: String {
        let points = Int(abs(indexDelta).rounded())
        if isPositive { return "压力比其它日子平均低 \(points) 点" }
        if isNegative { return "压力比其它日子平均高 \(points) 点" }
        return "与其它日子差别不大"
    }

    var hrvText: String {
        let d = Int(abs(hrvDelta).rounded())
        if d < 1 { return "HRV 基本持平" }
        return hrvDelta > 0 ? "平均 HRV 高 \(d)ms" : "平均 HRV 低 \(d)ms"
    }

    var rhrText: String {
        let d = Int(abs(rhrDelta).rounded())
        if d < 1 { return "静息心率基本持平" }
        return rhrDelta < 0 ? "静息心率低 \(d)bpm" : "静息心率高 \(d)bpm"
    }
}

enum InsightCalculator {
    /// Every action compared across the trailing `window` days that have data.
    static func comparisons(days: [DailyStress], window: Int) -> [ActionComparison] {
        let slice = days.suffix(window).filter { $0.level != nil }
        return ActionTag.allCases
            .map { tag -> ActionComparison in
                let matching = slice.filter { ActionTags.set(for: $0).contains(tag) }
                let others = slice.filter { !ActionTags.set(for: $0).contains(tag) }
                return ActionComparison(tag: tag, matching: matching, others: others)
            }
            .sorted { lhs, rhs in
                let l = lhs.hasEnoughData ? abs(lhs.indexDelta) : -1
                let r = rhs.hasEnoughData ? abs(rhs.indexDelta) : -1
                return l > r
            }
    }
}
