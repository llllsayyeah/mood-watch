import SwiftUI

struct InsightView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var window = 60
    @State private var selected: ActionTag = .sleep7h

    private var comparisons: [ActionComparison] {
        InsightCalculator.comparisons(days: store.days, window: window)
    }

    private var current: ActionComparison? {
        comparisons.first { $0.tag == selected }
    }

    private var usable: [ActionComparison] {
        comparisons.filter { $0.hasEnoughData }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                    Picker("范围", selection: $window) {
                        Text("近 60 天").tag(60)
                        Text("近 30 天").tag(30)
                    }
                    .pickerStyle(.segmented)

                    Text("筛选习惯，对比「符合」与「不符合」的日子，看看哪些行动真的在改变你的压力。")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if usable.isEmpty {
                        emptyCard
                    } else {
                        actionsCard
                        if let current {
                            ComparisonCard(comparison: current)
                        }
                    }

                    Text("仅统计至少 5 天数据的行动，样本不足时不给结论。此处展示的是相关性，不代表因果。")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                        .lineSpacing(3)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("返回")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSecondary)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("行动 v.s. 压力趋势")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(usable.count) 项")
                .font(.captionText)
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.vertical, 12)
        .background(Theme.bg)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("数据还不够")
                .font(.cardTitle)
                .foregroundStyle(Theme.ink)
            Text("至少需要某个行动在近 \(window) 天里有 5 天符合、5 天不符合，才会给出对比。继续佩戴 Apple Watch 并记录感受，数据积累后这里会长出来。")
                .font(.bodyText)
                .foregroundStyle(Theme.inkSecondary)
                .lineSpacing(3)
        }
        .card()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "关键行动", subtitle: "点击查看对比详情")

            VStack(spacing: 8) {
                ForEach(comparisons) { comparison in
                    ActionRow(
                        comparison: comparison,
                        isSelected: comparison.tag == selected
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selected = comparison.tag
                        }
                    }
                }
            }
        }
        .card()
    }
}

// MARK: - Row

private struct ActionRow: View {
    let comparison: ActionComparison
    let isSelected: Bool
    var onTap: () -> Void

    private var tint: Color {
        if !comparison.hasEnoughData { return Theme.muted }
        if comparison.isPositive { return Theme.mint }
        if comparison.isNegative { return Theme.overload }
        return Theme.inkTertiary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(comparison.tag.emoji)
                    .font(.system(size: 16))
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(comparison.tag.title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(comparison.hasEnoughData
                         ? "\(comparison.percentText) · \(comparison.matchingDays)/\(comparison.matchingDays + comparison.otherDays) 天"
                         : "数据不足（符合 \(comparison.matchingDays) 天）")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if comparison.hasEnoughData {
                    VStack(spacing: 2) {
                        Text(comparison.impactLevel)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(tint)
                        Text(comparison.isPositive ? "积极" : (comparison.isNegative ? "消极" : "中性"))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    .frame(width: 34)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Theme.mintSoft : Theme.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.mint : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Comparison card

private struct ComparisonCard: View {
    let comparison: ActionComparison

    private var tint: Color {
        if comparison.isPositive { return Theme.mint }
        if comparison.isNegative { return Theme.overload }
        return Theme.inkTertiary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("「\(comparison.tag.title)」的日子里")
                    .font(.cardTitle)
                    .foregroundStyle(Theme.ink)
                Text("符合 \(comparison.matchingDays) 天 / 不符合 \(comparison.otherDays) 天")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkTertiary)
            }

            VStack(spacing: 14) {
                metricRow(
                    title: "综合压力",
                    matching: comparison.avgIndexMatching,
                    others: comparison.avgIndexOthers,
                    unit: "",
                    matchingTint: tint
                )
                metricRow(
                    title: "HRV",
                    matching: comparison.avgHrvMatching,
                    others: comparison.avgHrvOthers,
                    unit: "ms",
                    matchingTint: Theme.normal
                )
                metricRow(
                    title: "静息心率",
                    matching: comparison.avgRhrMatching,
                    others: comparison.avgRhrOthers,
                    unit: "bpm",
                    matchingTint: Theme.warn
                )
            }

            Hairline()

            VStack(alignment: .leading, spacing: 4) {
                Text(conclusion)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(comparison.hrvText)；\(comparison.rhrText)。")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
    }

    private var conclusion: String {
        if comparison.isPositive {
            return "综合压力比其它日子平均低 \(Int(abs(comparison.indexDelta).rounded())) 点，影响程度：\(comparison.impactLevel)。"
        }
        if comparison.isNegative {
            return "综合压力比其它日子平均高 \(Int(abs(comparison.indexDelta).rounded())) 点，影响程度：\(comparison.impactLevel)。"
        }
        return "与其它日子的压力差别不大，影响程度：\(comparison.impactLevel)。"
    }

    private func metricRow(
        title: String,
        matching: Double,
        others: Double,
        unit: String,
        matchingTint: Color
    ) -> some View {
        let peak = max(matching, others, 1)
        return VStack(spacing: 7) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                HStack(spacing: 10) {
                    Text("符合 \(Int(matching.rounded()))\(unit)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(matchingTint)
                    Text("不符合 \(Int(others.rounded()))\(unit)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkTertiary)
                }
            }

            VStack(spacing: 5) {
                bar(fraction: matching / peak, tint: matchingTint, height: 8)
                bar(fraction: others / peak, tint: Theme.muted.opacity(0.55), height: 6)
            }
        }
    }

    private func bar(fraction: Double, tint: Color, height: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(tint)
                    .frame(width: max(8, geo.size.width * min(1, max(0, fraction))))
            }
        }
        .frame(height: height)
    }
}
