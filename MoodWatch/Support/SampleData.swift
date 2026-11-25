import Foundation

/// Small deterministic PRNG so the demo data is identical on every launch and device.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed &* 6364136223846793005 &+ 1442695040888963407 }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(UInt64(1) << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}

enum SampleData {
    /// Builds the demo history: 60 days of HRV / RHR with a few low and a few excellent days.
    static func days(count: Int = 60, now: Date = Date()) -> [DailyStress] {
        var rng = SeededGenerator(seed: 20_251_125)
        let cal = Calendar.current
        var result: [DailyStress] = []
        var hrvHistory: [Double] = []

        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: now)) else { continue }
            let phase = Double(offset) / 7.0
            let wave = sin(phase) * 6.0 + cos(phase * 0.6) * 4.0
            let noise = rng.double(in: -5.0...5.0)
            var hrv = 58.0 + wave + noise
            // A handful of high-stress days and a couple of great ones.
            if offset == 3 || offset == 9 || offset == 17 { hrv -= rng.double(in: 12...20) }
            if offset == 5 || offset == 24 { hrv += rng.double(in: 10...16) }
            hrv = max(22, min(120, hrv))

            // Roughly one day in twenty has no watch data at all.
            let noData = offset != 0 && rng.double(in: 0...1) < 0.05
            let rhr = 62.0 + rng.double(in: -4.0...6.0)

            let baseline = hrvHistory.suffix(30)
            let mean = baseline.isEmpty ? hrv : baseline.reduce(0, +) / Double(baseline.count)
            let variance = baseline.count > 1
                ? baseline.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(baseline.count - 1)
                : 1
            let sd = max(1, sqrt(variance))
            let index = StressMath.index(current: hrv, baselineMean: mean, baselineStd: sd)

            result.append(
                DailyStress(
                    date: date,
                    hrv: (hrv * 10).rounded() / 10,
                    rhr: (rhr * 10).rounded() / 10,
                    index: (index * 10).rounded() / 10,
                    level: noData ? nil : StressLevel.from(index: index)
                )
            )
            hrvHistory.append(hrv)
        }
        return result
    }

    /// Intraday HRV curve for one day, 08:00 → 20:15.
    static func todayCurve(for day: DailyStress, now: Date = Date()) -> [HRVPoint] {
        var rng = SeededGenerator(seed: 7_772_001)
        let cal = Calendar.current
        let start = cal.startOfDay(for: day.date)
        let hours: [Double] = [8, 9.5, 11, 12.5, 14, 16, 18, 19.5, 20.25]
        return hours.map { hour in
            let base = day.hrv + rng.double(in: -6.0...6.0)
            let drift = sin(hour / 3.0) * 4
            let value = max(18, min(140, base + drift))
            let time = start.addingTimeInterval(hour * 3600)
            return HRVPoint(time: time, value: (value * 10).rounded() / 10)
        }
    }

    /// Last 7 days' resting heart rate, for the mini chart.
    static func rhrSeries(from days: [DailyStress]) -> [Double] {
        days.suffix(7).map { $0.rhr }
    }

    static func hrvSeries(from days: [DailyStress]) -> [Double] {
        days.suffix(7).map { $0.hrv }
    }

    static func moods(now: Date = Date()) -> [MoodEntry] {
        let cal = Calendar.current
        func at(_ hour: Int, _ minute: Int) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }
        return [
            MoodEntry(
                date: at(9, 12),
                stateName: "压力",
                valence: .negative,
                tags: ["🧑‍💻 工作", "☕️ 咖啡因"],
                note: "周会排期太满，心跳一直很快。"
            ),
            MoodEntry(
                date: at(13, 40),
                stateName: "满足",
                valence: .positive,
                tags: ["🍽️ 食物"],
                note: "下楼吃了碗热汤面，整个人缓过来了。"
            ),
            MoodEntry(
                date: at(18, 5),
                stateName: "松弛",
                valence: .positive,
                tags: ["🧘 冥想", "☀️ 天气"],
                note: "晒了十分钟太阳，做了三轮 4-7-8 呼吸。"
            ),
            MoodEntry(
                date: at(20, 15),
                stateName: "平静",
                valence: .neutral,
                tags: ["🛌 睡眠"],
                note: "准备早点睡，明天要早起。"
            ),
        ]
    }
}
