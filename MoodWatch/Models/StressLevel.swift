import SwiftUI

// MARK: - Stress levels (see docs/DESIGN.md §4)

enum StressLevel: Int, CaseIterable, Codable, Identifiable {
    case overload = 1
    case alert = 2
    case normal = 3
    case great = 4

    var id: Int { rawValue }

    /// Default display name; user can rename it in Settings.
    var defaultName: String {
        switch self {
        case .overload: return "压力过载"
        case .alert: return "注意压力"
        case .normal: return "状态正常"
        case .great: return "状态优秀"
        }
    }

    /// Short label used on the gauge scale.
    var scaleLabel: String {
        switch self {
        case .overload: return "过载"
        case .alert: return "注意"
        case .normal: return "正常"
        case .great: return "优秀"
        }
    }

    var color: Color {
        switch self {
        case .overload: return Theme.overload
        case .alert: return Theme.warn
        case .normal: return Theme.normal
        case .great: return Theme.great
        }
    }

    var insight: String {
        switch self {
        case .overload:
            return "此刻你的 HRV 低于日常水平，身体在硬扛。偶尔低值很正常，但长时间偏低就要停下来：散个步、好好吃顿饭、睡个好觉，别把自己耗空。"
        case .alert:
            return "此刻你的 HRV 略低于日常水平，压力开始积累。给自己留一点放松的余地，别硬撑，张弛有度才能走得更远。"
        case .normal:
            return "HRV 处于你的日常水平，身心压力可控。保持现在的节奏就好，记得不要过度挑战自己。"
        case .great:
            return "HRV 高于日常水平，身心放松、恢复良好。此刻的你可以从容应对工作与运动，也适合去玩去野。"
        }
    }

    /// Maps a 0–100 stress index onto a level.
    static func from(index: Double) -> StressLevel {
        switch index {
        case ..<38: return .great
        case 38..<52: return .normal
        case 52..<62: return .alert
        default: return .overload
        }
    }
}

/// One day of physiological data.
struct DailyStress: Identifiable, Equatable {
    var id: Date { date }
    let date: Date
    /// RMSSD in ms.
    let hrv: Double
    /// Resting heart rate in bpm.
    let rhr: Double
    /// 0–100, higher means more strained.
    let index: Double
    /// `nil` means no data was recorded for that day.
    let level: StressLevel?
    /// HRV above this value cannot be interpreted.
    var isUndefined: Bool { hrv > 180 }

    var isNoData: Bool { level == nil }
}

/// Point of the intraday HRV curve.
struct HRVPoint: Identifiable, Equatable {
    var id: Date { time }
    let time: Date
    let value: Double
}

// MARK: - Index computation

enum StressMath {
    static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    static func std(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 1 }
        let m = mean(values)
        let variance = values.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(values.count - 1)
        return max(1, sqrt(variance))
    }

    /// z-score against the trailing baseline, mapped to 0–100.
    static func index(current: Double, baselineMean: Double, baselineStd: Double) -> Double {
        guard current > 0, current <= 180, baselineMean > 0 else { return 50 }
        let z = (current - baselineMean) / baselineStd
        let raw = 50 - z * 18
        return min(100, max(0, raw))
    }

    /// Trailing baseline from the days before `date`.
    static func baseline(for date: Date, in days: [DailyStress], window: Int = 30) -> (mean: Double, std: Double) {
        let candidates = days
            .filter { $0.date < Calendar.current.startOfDay(for: date) && $0.hrv > 0 && $0.hrv <= 180 }
            .suffix(window)
            .map { $0.hrv }
        return (mean(candidates), std(candidates))
    }
}
