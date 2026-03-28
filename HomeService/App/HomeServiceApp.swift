import SwiftUI

@main
struct HomeServiceApp: App {
    @State private var appStore = AppStore()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var isOnboardingComplete = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environment(appStore)
                        .environment(subscriptionManager)
                        .transition(.opacity)
                } else {
                    OnboardingContainerView(isOnboardingComplete: $isOnboardingComplete)
                        .environment(subscriptionManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
            .onChange(of: isOnboardingComplete) { _, newValue in
                if newValue {
                    hasCompletedOnboarding = true
                }
            }
            .task {
                // Initial CloudKit sync
                await CloudKitManager.shared.syncAll(appStore: appStore)
            }
        }
    }
}
