import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @Environment(\.horizontalSizeClass) private var sizeClass

    enum Tab: String, CaseIterable {
        case home = "Home"
        case log = "Log"
        case timeline = "Timeline"
        case stats = "Stats"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .log: return "plus.circle.fill"
            case .timeline: return "clock.fill"
            case .stats: return "chart.bar.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad: use sidebar navigation
                NavigationSplitView {
                    List(selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Label(tab.rawValue, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .navigationTitle("Dwello")
                    .listStyle(.sidebar)
                } detail: {
                    tabContent
                }
            } else {
                // iPhone: custom tab bar
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedTab) {
                        HomeTabView().tag(Tab.home)
                        LogTabView().tag(Tab.log)
                        TimelineTabView().tag(Tab.timeline)
                        StatsTabView().tag(Tab.stats)
                        ProfileTabView().tag(Tab.profile)
                    }
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home: HomeTabView()
        case .log: LogTabView()
        case .timeline: TimelineTabView()
        case .stats: StatsTabView()
        case .profile: ProfileTabView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Button(action: {
                    HBHaptic.light()
                    withAnimation(HBAnimation.springInteractive) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        if tab == .log {
                            ZStack {
                                Circle()
                                    .fill(Color.hbPrimary)
                                    .frame(width: 52, height: 52)
                                    .hbShadow(.cta)

                                Image(systemName: "plus")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -10)
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .hbPrimary : .hbTextSecondary)
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)

                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .hbPrimary : .hbTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
                .accessibilityLabel(tab == .log ? "Add new log entry" : tab.rawValue)
                .accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.top, HBSpacing.sm)
        .padding(.bottom, HBSpacing.lg)
        .background(
            Color.hbSurface
                .hbShadow(.lg)
                .ignoresSafeArea()
        )
    }
}
