import SwiftUI

struct TrendView: View {
    @EnvironmentObject private var store: AppStore
    @State private var window = 14

    private var slice: [DailyStress] {
        Array(store.days.suffix(window))
    }

    var body: some View {
        PageScaffold(
            title: "趋势",
            subtitle: "综合压力状态 · 近 \(window) 天"
        ) {
            Picker("范围", selection: $window) {
                Text("14 天").tag(14)
                Text("60 天").tag(60)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "每日压力指数",
                    subtitle: "柱子越高，压力越大",
                    trailing: "均值 \(Int(StressMath.mean(slice.compactMap { $0.level == nil ? nil : $0.index }).rounded()))"
                )
                LevelBarChart(days: slice, height: 180)
                HStack {
                    Text(Fmt.dayMonth.string(from: slice.first?.date ?? Date()))
                    Spacer()
                    Text("今天")
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkTertiary)
            }
            .card()

            DistributionCard(distribution: store.distribution(window: window), total: slice.count)

            HStack(spacing: Theme.cardSpacing) {
                MetricCard(
                    title: "平均 HRV",
                    value: "\(Int(StressMath.mean(slice.map { $0.hrv }).rounded()))",
                    unit: "ms",
                    series: slice.suffix(7).map { $0.hrv },
                    tint: Theme.normal
                )
                MetricCard(
                    title: "静息心率",
                    value: "\(Int(StressMath.mean(slice.map { $0.rhr }).rounded()))",
                    unit: "bpm",
                    series: slice.suffix(7).map { $0.rhr },
                    tint: Theme.warn
                )
            }

            Text("HRV 个体差异很大，建议连续佩戴两周以上；单日数值波动属正常现象。")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.inkTertiary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
        }
    }
}

struct DistributionCard: View {
    let distribution: [(level: StressLevel, count: Int)]
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "等级分布", trailing: "共 \(total) 天")

            VStack(spacing: 12) {
                ForEach(distribution, id: \.level) { item in
                    HStack(spacing: 10) {
                        Text(item.level.defaultName)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 64, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.surfaceAlt)
                                Capsule()
                                    .fill(item.level.color)
                                    .frame(width: max(6, geo.size.width * fraction(item.count)))
                            }
                        }
                        .frame(height: 8)

                        Text("\(item.count) 天")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.inkSecondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
        .card()
    }

    private func fraction(_ count: Int) -> Double {
        guard total > 0 else { return 0 }
        let maxCount = max(1, distribution.map { $0.count }.max() ?? 1)
        return Double(count) / Double(maxCount)
    }
}
