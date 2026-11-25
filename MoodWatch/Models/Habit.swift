import Foundation

// MARK: - Habits shown on the Today page and checked off on the Actions page

struct Habit: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case sun, water, breath, sleep, caffeine
    }

    let id: String
    let kind: Kind
    let title: String
    let emoji: String
    let unit: String
    /// Daily target in `unit`.
    var goal: Double
    /// What has been done today.
    var progress: Double

    var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(1, max(0, progress / goal))
    }

    var isComplete: Bool { progress >= goal }

    var progressText: String {
        let g = goal.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(goal)) : String(format: "%.1f", goal)
        let p = progress.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(progress)) : String(format: "%.1f", progress)
        return "\(p)/\(g) \(unit)"
    }
}

extension Habit {
    static func defaults() -> [Habit] {
        [
            Habit(id: "sun", kind: .sun, title: "晒太阳", emoji: "🌞", unit: "分钟", goal: 20, progress: 12),
            Habit(id: "water", kind: .water, title: "喝水", emoji: "💧", unit: "毫升", goal: 2000, progress: 1400),
            Habit(id: "breath", kind: .breath, title: "呼吸正念", emoji: "🧘", unit: "分钟", goal: 5, progress: 5),
            Habit(id: "sleep", kind: .sleep, title: "睡够 7 小时", emoji: "😴", unit: "小时", goal: 7, progress: 7.2),
            Habit(id: "caffeine", kind: .caffeine, title: "咖啡因控制", emoji: "☕️", unit: "毫克", goal: 100, progress: 80),
        ]
    }
}
