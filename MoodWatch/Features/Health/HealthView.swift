import SwiftUI

struct HealthFactor: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let delta: Double
}

struct HealthView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAgeInfo = false

    private var bioAge: Int { 28 }
    private var realAge: Int { 30 }

    private let factors: [HealthFactor] = [
        HealthFactor(name: "睡眠时长", value: "7 小时 12 分", delta: -0.8),
        HealthFactor(name: "睡眠一致性", value: "82 分", delta: -0.4),
        HealthFactor(name: "静息心率", value: "62 bpm", delta: -0.3),
        HealthFactor(name: "步数", value: "8,942 步", delta: -0.5),
        HealthFactor(name: "最大摄氧量", value: "42.1", delta: -0.9),
        HealthFactor(name: "力量训练时长/周", value: "1 小时 40 分", delta: 0.6),
    ]

    var body: some View {
        PageScaffold(
            title: "健康",
            subtitle: "身体年龄 · 睡眠 · 活动"
        ) {
            BioAgeCard(bioAge: bioAge, realAge: realAge) {
                showAgeInfo = true
            }

            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "影响因素", subtitle: "以上不包含今日数据")

                VStack(spacing: 0) {
                    ForEach(factors) { factor in
                        HStack {
                            Text(factor.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(factor.value)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.inkSecondary)
                            Text(deltaText(factor.delta))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(factor.delta <= 0 ? Theme.mint : Theme.overload)
                                .frame(width: 56, alignment: .trailing)
                        }
                        .padding(.vertical, 11)

                        if factor.id != factors.last?.id {
                            Hairline()
                        }
                    }
                }
            }
            .card()

            SleepCard()

            Text("Mood Watch 不是医疗设备，所提供的信息仅供参考，不能替代专业的医疗诊断与治疗。若长期压力过大难以自我调节，请寻求专业帮助。")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.inkTertiary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
        }
        .alert("身体年龄是什么？", isPresented: $showAgeInfo) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("身体年龄基于最大摄氧量、静息心率、睡眠与运动等历史数据估算，反映身体机能的相对状态，不代表真实生理年龄，也不构成医学结论。")
        }
    }

    private func deltaText(_ delta: Double) -> String {
        let sign = delta <= 0 ? "" : "+"
        return "\(sign)\(String(format: "%.1f", delta)) 岁"
    }
}

// MARK: - Bio age

struct BioAgeCard: View {
    let bioAge: Int
    let realAge: Int
    var onInfo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("身体年龄")
                    .font(.cardTitle)
                    .foregroundStyle(Theme.ink)
                Button(action: onInfo) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkTertiary)
                }
                .buttonStyle(.plain)
                Spacer()
                Pill(text: "年轻中", tint: Theme.mint, filled: false)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(bioAge)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text("岁")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("实际年龄 \(realAge) 岁")
                        .font(.captionText)
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkSecondary)
                    Text("比实际年龄年轻 \(realAge - bioAge) 岁")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.mint)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.mint.opacity(0.6), Theme.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.68)
                }
            }
            .frame(height: 10)

            HStack {
                Text("加速衰老")
                Spacer()
                Text("正常范围")
                Spacer()
                Text("加速年轻中")
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.inkTertiary)

            Hairline()

            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkTertiary)
                Text("每日凌晨更新数据")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkTertiary)
                Spacer()
            }
        }
        .card()
    }
}

// MARK: - Sleep

struct SleepStage {
    let name: String
    let fraction: Double
    let color: Color
}

struct SleepCard: View {
    private let stages: [SleepStage] = [
        SleepStage(name: "清醒", fraction: 0.06, color: Theme.warn),
        SleepStage(name: "快速眼动", fraction: 0.22, color: Theme.great),
        SleepStage(name: "核心睡眠", fraction: 0.52, color: Theme.normal),
        SleepStage(name: "深度睡眠", fraction: 0.20, color: Color(hex: 0x3F7FBF)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "睡眠时长 & 质量", trailing: "较前 7 天 +4 分")

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("7")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("小时")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                Text("12")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("分")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("质量 82 分")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.mint)
                    Text("良好")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }

            GeometryReader { geo in
                HStack(spacing: 3) {
                    ForEach(stages.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(stages[index].color.opacity(0.85))
                            .frame(width: max(2, geo.size.width * stages[index].fraction - 3))
                    }
                }
            }
            .frame(height: 12)

            HStack(spacing: 12) {
                ForEach(stages.indices, id: \.self) { index in
                    HStack(spacing: 4) {
                        Circle().fill(stages[index].color).frame(width: 6, height: 6)
                        Text(stages[index].name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .card()
    }
}
