import SwiftUI

struct ActionsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showMoodSheet = false
    @State private var showInsightTeaser = false

    var body: some View {
        PageScaffold(
            title: "行动",
            subtitle: "记录 · 习惯 · 与压力的关系",
            trailing: AnyView(
                Button {
                    showMoodSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("记录")
                    }
                }
                .buttonStyle(SoftButtonStyle(tint: Theme.mint, filled: true))
            )
        ) {
            MoodTimelineCard(entries: store.moods) { entry in
                store.deleteMood(entry)
            }

            HabitGridCard(habits: store.habits) { habit in
                store.toggleHabit(habit)
            }

            Button {
                showInsightTeaser = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.mintSoft).frame(width: 44, height: 44)
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.mint)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("行动 v.s. 压力趋势")
                            .font(.cardTitle)
                            .foregroundStyle(Theme.ink)
                        Text("透视生活习惯如何改变你的压力趋势")
                            .font(.captionText)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            .buttonStyle(.plain)
            .card()
        }
        .sheet(isPresented: $showMoodSheet) {
            MoodLogSheet().environmentObject(store)
        }
        .sheet(isPresented: $showInsightTeaser) {
            InsightView().environmentObject(store)
        }
    }
}

// MARK: - Mood timeline

struct MoodTimelineCard: View {
    let entries: [MoodEntry]
    var onDelete: (MoodEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "今日心情", trailing: entries.isEmpty ? nil : "\(entries.count) 条")

            if entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("还没有记录")
                        .font(.bodyText)
                        .foregroundStyle(Theme.inkSecondary)
                    Text("在「行动 - 感受」里随手记一笔，标记相关标签，积累足够后这里会呈现情绪趋势。")
                        .font(.captionText)
                        .foregroundStyle(Theme.inkTertiary)
                        .lineSpacing(3)
                }
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 0) {
                    ForEach(entries.indices, id: \.self) { index in
                        entryRow(entries[index])
                        if index < entries.count - 1 {
                            Hairline().padding(.leading, 46)
                        }
                    }
                }
            }
        }
        .card()
    }

    private func entryRow(_ entry: MoodEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.emoji)
                .font(.system(size: 22))
                .frame(width: 34, height: 34)
                .background(Circle().fill(entry.valence.color.opacity(0.14)))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.stateName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(Fmt.hourMinute.string(from: entry.date))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkTertiary)
                }

                if !entry.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(entry.tags.prefix(3)), id: \.self) { tag in
                            Pill(text: tag, tint: entry.valence == .neutral ? Theme.mint : entry.valence.color)
                        }
                    }
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            Button {
                onDelete(entry)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Habit grid

struct HabitGridCard: View {
    let habits: [Habit]
    var onToggle: (Habit) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "习惯打卡", subtitle: "点击即可完成今日目标")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(habits) { habit in
                    Button {
                        onToggle(habit)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(habit.emoji)
                                    .font(.system(size: 18))
                                Spacer()
                                if habit.isComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Theme.mint)
                                }
                            }
                            Text(habit.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Text(habit.progressText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.inkTertiary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(habit.isComplete ? Theme.mintSoft : Theme.surfaceAlt)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }
}
