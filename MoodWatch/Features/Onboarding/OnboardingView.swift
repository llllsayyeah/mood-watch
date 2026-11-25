import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
    let highlight: String
}

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var index = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "lock.shield",
            title: "隐私优先",
            body: "你的健康与感受记录默认只保存在这台设备上，通过 iCloud 加密同步。除非你明确同意，我们不会上传任何数据。",
            highlight: "本地处理"
        ),
        OnboardingPage(
            symbol: "waveform.path.ecg",
            title: "看懂身体压力",
            body: "HRV（心率变异性）反映的是身体压力，而不是心理压力。它和静息心率一起，能说明你今天是硬扛，还是游刃有余。",
            highlight: "HRV · 静息心率"
        ),
        OnboardingPage(
            symbol: "heart.text.square",
            title: "获取健康权限",
            body: "授权读取心率变异性、静息心率、睡眠与活动数据后，Mood Watch 才能为你算出每日压力状态与身体年龄。",
            highlight: "只读 · 可随时撤回"
        ),
        OnboardingPage(
            symbol: "sparkles",
            title: "一起从容一点",
            body: "记录一次感受、晒十分钟太阳、做三轮呼吸——这些小事都会累积成趋势，让你更了解自己。",
            highlight: "从今天开始"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("跳过") { onFinish() }
                    .font(.captionText)
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)

            TabView(selection: $index) {
                ForEach(pages.indices, id: \.self) { offset in
                    pageView(pages[offset])
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Theme.mint : Theme.surfaceAlt)
                        .frame(width: i == index ? 22 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: index)
                }
            }
            .padding(.bottom, 22)

            Button {
                if index < pages.count - 1 {
                    withAnimation { index += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(index < pages.count - 1 ? "继续" : "开始吧")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.mint)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.pagePadding)
            .padding(.bottom, 18)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(Theme.mintSoft)
                    .frame(width: 150, height: 150)
                Circle()
                    .stroke(Theme.mint.opacity(0.35), lineWidth: 1)
                    .frame(width: 190, height: 190)
                Image(systemName: page.symbol)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.mint)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 12)

            Text(page.highlight)
                .font(.tagText)
                .foregroundStyle(Theme.mint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.mint.opacity(0.14)))

            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            Text(page.body)
                .font(.bodyText)
                .foregroundStyle(Theme.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 40)
        }
        .padding(.horizontal, Theme.pagePadding + 4)
    }
}
