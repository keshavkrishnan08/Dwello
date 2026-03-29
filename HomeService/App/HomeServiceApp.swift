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
                // Check iCloud and restore data if local is empty
                await CloudKitManager.shared.checkStatus()

                if appStore.logs.isEmpty {
                    let cloud = await CloudKitManager.shared.pullAll()
                    if !cloud.logs.isEmpty {
                        await MainActor.run {
                            appStore.restoreFromCloud(
                                logs: cloud.logs,
                                contractors: cloud.contractors,
                                reminders: cloud.reminders,
                                appliances: cloud.appliances
                            )
                        }
                    }
                } else {
                    // Push local data to cloud
                    await CloudKitManager.shared.syncAll(appStore: appStore)
                }

                // Load StoreKit products and check entitlements
                await subscriptionManager.loadProducts()
                await subscriptionManager.updatePurchasedProducts()

                // Notifications
                NotificationManager.shared.registerCategories()
                _ = await NotificationManager.shared.requestPermission()
                NotificationManager.shared.scheduleWeeklySummary(
                    overdueCount: appStore.overdueReminders.count,
                    upcomingCount: appStore.upcomingReminders.count,
                    healthScore: appStore.homeHealthScore
                )
                NotificationManager.shared.scheduleSeasonalNudge()
            }
        }
    }
}
