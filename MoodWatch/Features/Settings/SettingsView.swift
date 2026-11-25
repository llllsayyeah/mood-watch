import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var editingLevel: StressLevel?
    @State private var draftName: String = ""
    @State private var showResetDone = false
    @State private var showClearConfirm = false
    @State private var showCopied = false

    var body: some View {
        PageScaffold(
            title: "设置",
            subtitle: "Mood Watch 1.0.0"
        ) {
            levelNamesCard
            goalsCard
            notificationCard
            privacyCard
            aboutCard
        }
        .alert("重命名压力状态", isPresented: renameAlertBinding) {
            TextField("名称", text: $draftName)
            Button("取消", role: .cancel) { editingLevel = nil }
            Button("保存") {
                if let level = editingLevel {
                    store.rename(level: level, to: draftName)
                }
                editingLevel = nil
            }
        } message: {
            Text("名称会同步显示在今日页的仪表盘上，最多 8 个字。")
        }
        .alert("已重新生成演示数据", isPresented: $showResetDone) {
            Button("好", role: .cancel) {}
        } message: {
            Text("历史数据已重新生成，习惯与记录也已还原为初始状态。")
        }
        .alert("清空所有记录？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) { store.clearAll() }
        } message: {
            Text("这会删除本机保存的全部心情记录、习惯进度与自定义名称，且无法恢复。")
        }
        .alert("已复制到剪贴板", isPresented: $showCopied) {
            Button("好", role: .cancel) {}
        }
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(
            get: { editingLevel != nil },
            set: { if !$0 { editingLevel = nil } }
        )
    }

    // MARK: - Sections

    private var levelNamesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "压力状态名称", subtitle: "四档状态都可以改成你的说法")

            VStack(spacing: 0) {
                ForEach(StressLevel.allCases) { level in
                    Button {
                        editingLevel = level
                        draftName = store.name(for: level)
                    } label: {
                        HStack(spacing: 10) {
                            Circle().fill(level.color).frame(width: 8, height: 8)
                            Text(store.name(for: level))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("默认「\(level.defaultName)」")
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(Theme.inkTertiary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.inkTertiary)
                        }
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)

                    if level != StressLevel.allCases.last {
                        Hairline()
                    }
                }
            }
        }
        .card()
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "每日目标", subtitle: "按自己的节奏来，不用追满")

            VStack(spacing: 12) {
                ForEach(store.habits) { habit in
                    HStack(spacing: 10) {
                        Text(habit.emoji).font(.system(size: 16))
                        Text(habit.title)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(habit.goalText) \(habit.unit)")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
        }
        .card()
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "通知")

            Toggle(isOn: Binding(
                get: { store.notifyStress },
                set: { store.notifyStress = $0; store.save() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("压力状态提醒")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("HRV 明显低于基线时提醒你休息")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            .tint(Theme.mint)

            Hairline()

            Toggle(isOn: Binding(
                get: { store.notifyDigest },
                set: { store.notifyDigest = $0; store.save() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("每日小结")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("每晚 21:00 汇总今日状态与习惯")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            .tint(Theme.mint)
        }
        .card()
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "隐私与数据", subtitle: "主要数据保存在本机")

            Text("Mood Watch 默认不联网、不上传。所有心情记录、习惯进度与偏好设置都写入本机 App 沙盒，卸载即删除。")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button {
                    copyExport()
                } label: {
                    rowLabel(title: "复制数据（JSON）", symbol: "doc.on.doc")
                }
                .buttonStyle(.plain)

                Hairline()

                Button {
                    store.resetDemoData()
                    showResetDone = true
                } label: {
                    rowLabel(title: "重新生成演示数据", symbol: "arrow.clockwise")
                }
                .buttonStyle(.plain)

                Hairline()

                Button {
                    showClearConfirm = true
                } label: {
                    rowLabel(title: "清空所有记录", symbol: "trash", danger: true)
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "关于")

            VStack(alignment: .leading, spacing: 6) {
                Text("Mood Watch 1.0.0 (1)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("净室复刻练习：界面与交互参考 StressWatch 的信息结构，代码、配色与素材均为本项目原创，未使用原 App 的任何二进制、图片或字体资源。")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Hairline()

            Button {
                store.onboardingDone = false
                store.save()
            } label: {
                rowLabel(title: "重看新手引导", symbol: "sparkles")
            }
            .buttonStyle(.plain)
        }
        .card()
    }

    // MARK: - Bits

    private func rowLabel(title: String, symbol: String, danger: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(danger ? Theme.overload : Theme.inkSecondary)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(danger ? Theme.overload : Theme.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func copyExport() {
        let payload: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "moods": store.moods.count,
            "habits": store.habits.map { ["id": $0.id, "progress": $0.progress, "goal": $0.goal] },
            "levelNames": store.customLevelNames,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let text = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = text
            showCopied = true
        }
    }
}

extension Habit {
    var goalText: String {
        goal.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(goal)) : String(format: "%.1f", goal)
    }
}
