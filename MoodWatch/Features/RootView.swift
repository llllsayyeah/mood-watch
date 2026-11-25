import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if store.onboardingDone {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        store.onboardingDone = true
                        store.save()
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("今日", systemImage: "sun.max") }
                .tag(0)

            TrendView()
                .tabItem { Label("趋势", systemImage: "chart.bar") }
                .tag(1)

            ActionsView()
                .tabItem { Label("行动", systemImage: "checkmark.circle") }
                .tag(2)

            HealthView()
                .tabItem { Label("健康", systemImage: "heart.text.square") }
                .tag(3)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(4)
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Page scaffold shared by the five tabs

struct PageScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    var trailing: AnyView?
    var content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        trailing: AnyView? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                header
                    .padding(.bottom, 4)
                content()
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.pageTitle)
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.captionText)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                trailing
            }
        }
    }
}
