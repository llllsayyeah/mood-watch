import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showMoodSheet = false
    @State private var quickMood: MoodValence?

    var body: some View {
        PageScaffold(
            title: "Hi, 你 👋",
            subtitle: "\(Fmt.dayMonth.string(from: store.today.date)) \(Fmt.weekdayShort(store.today.date))",
            trailing: AnyView(
                Text("数据更新于 \(Fmt.hourMinute.string(from: store.lastUpdate))")
                    .font(.captionText)
                    .foregroundStyle(Theme.inkTertiary)
            )
        ) {
            StressGaugeCard(day: store.today, levelName: store.today.level.map { store.name(for: $0) } ?? "暂无今日数据")

            HRVTrendCard(points: store.curve, baseline: store.baselineHRV)

            MoodCard(quickMood: $quickMood, onRecord: { showMoodSheet = true })

            HabitsCard(habits: Array(store.habits.prefix(4)))

            if let yesterday = store.yesterday {
                YesterdayCard(day: yesterday)
            }
        }
        .sheet(isPresented: $showMoodSheet) {
            MoodLogSheet().environmentObject(store)
        }
    }
}

// MARK: - Gauge

struct StressGaugeCard: View {
    let day: DailyStress
    let levelName: String

    @State private var animatedProgress: Double = 0
    @State private var showInsight = false

    private var level: StressLevel? { day.level }
    private var tint: Color { level?.color ?? Theme.muted }
    private var indexText: String {
        day.level == nil ? "--" : String(Int(day.index.rounded()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    GaugeArc(progress: animatedProgress, lineWidth: 20, tint: tint)
                        .frame(width: 186, height: 186)

                    VStack(spacing: 2) {
                        Text(levelName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(tint)
                        Text(indexText)
                            .font(.displayNumber)
                            .monospacedDigit()
                            .foregroundStyle(Theme.ink)
                            .contentTransitionNumeric()
                        Text(day.level == nil ? "HRV -- ms" : "HRV \(Int(day.hrv.rounded())) ms")
                            .font(.captionText)
                            .monospacedDigit()
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(StressLevel.allCases.reversed()) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 7, height: 7)
                                .opacity(level == item ? 1 : 0.4)
                            Text(item.scaleLabel)
                                .font(.system(size: 13, weight: level == item ? .bold : .regular, design: .rounded))
                                .foregroundStyle(level == item ? item.color : Theme.inkTertiary)
                        }
                    }

                    Text("最近一次\n\(Fmt.hourMinute.string(from: day.date))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }

            Hairline()

            HStack {
                Text("今日综合压力状态")
                    .font(.captionText)
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Button(showInsight ? "收起解读" : "详细解读") {
                    withAnimation(.easeInOut(duration: 0.25)) { showInsight.toggle() }
                }
                .buttonStyle(SoftButtonStyle(tint: tint, filled: false))
            }

            if showInsight {
                Text(day.level?.insight ?? "今日佩戴时长不足，暂无 HRV 数据。保持佩戴即可积累属于你的基线。")
                    .font(.bodyText)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card()
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                animatedProgress = day.index / 100
            }
        }
        .onChange(of: day.index) { newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue / 100
            }
        }
    }
}

// MARK: - Intraday HRV

struct HRVTrendCard: View {
    let points: [HRVPoint]
    let baseline: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "今日 HRV 趋势",
                subtitle: "越平稳，说明身体越放松",
                trailing: baseline > 0 ? "近 30 天平均 \(Int(baseline.rounded()))ms" : nil
            )

            ZStack(alignment: .topLeading) {
                ChartGrid()
                Sparkline(values: points.map { $0.value }, tint: Theme.mint, height: 108)
                    .padding(.leading, 26)
                    .padding(.bottom, 18)
            }
            .frame(height: 128)

            HStack {
                ForEach(["00:00", "06:00", "12:00", "18:00", "24:00"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                    if label != "24:00" { Spacer() }
                }
            }
            .padding(.leading, 26)
        }
        .card()
    }
}

private struct ChartGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("180")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(width: 22, alignment: .leading)
                Rectangle().fill(Theme.hairline).frame(height: 0.5)
            }
            Spacer()
            HStack {
                Text("90")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(width: 22, alignment: .leading)
                Rectangle().fill(Theme.hairline).frame(height: 0.5)
            }
            Spacer()
            HStack {
                Text("0")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(width: 22, alignment: .leading)
                Rectangle().fill(Theme.hairline).frame(height: 0.5)
            }
        }
        .padding(.bottom, 18)
    }
}

// MARK: - Mood

struct MoodCard: View {
    @Binding var quickMood: MoodValence?
    var onRecord: () -> Void

    private let faces: [MoodValence] = [.veryPositive, .positive, .neutral, .negative, .veryNegative]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "你现在的感受如何？", subtitle: "记录一次，帮你看清情绪与压力的关系")

            HStack(spacing: 10) {
                ForEach(faces) { face in
                    Button {
                        quickMood = face
                        onRecord()
                    } label: {
                        Text(face.face)
                            .font(.system(size: 26))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle().fill(quickMood == face ? face.color.opacity(0.2) : Theme.surfaceAlt)
                            )
                            .overlay(
                                Circle().stroke(quickMood == face ? face.color : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(quickMood == face ? 1.06 : 1)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }

            Button(action: onRecord) {
                HStack {
                    Text("记录感受")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SoftButtonStyle(tint: Theme.mint, filled: false))
        }
        .card()
    }
}

// MARK: - Habits

struct HabitsCard: View {
    let habits: [Habit]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "关键行动", trailing: "今日")

            VStack(spacing: 14) {
                ForEach(habits) { habit in
                    HStack(spacing: 12) {
                        Text(habit.emoji)
                            .font(.system(size: 18))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Theme.surfaceAlt))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(.bodyText)
                                .foregroundStyle(Theme.ink)
                            Text(habit.progressText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.inkTertiary)
                        }
                        Spacer()
                        MiniRing(progress: habit.fraction, size: 30)
                    }
                }
            }
        }
        .card()
    }
}

// MARK: - Yesterday

struct YesterdayCard: View {
    let day: DailyStress

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(day.level?.color ?? Theme.muted)
                .frame(width: 4, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text("或许此刻你想查看")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkTertiary)
                Text("昨日（\(Fmt.dayMonth.string(from: day.date))）的压力状态")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surfaceAlt)
        )
    }
}

// MARK: - Helpers

extension View {
    @ViewBuilder
    func contentTransitionNumeric() -> some View {
        if #available(iOS 17.0, *) {
            self.contentTransition(.numericText())
        } else {
            self
        }
    }
}
