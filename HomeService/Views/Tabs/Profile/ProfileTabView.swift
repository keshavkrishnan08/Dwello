import SwiftUI

struct ProfileTabView: View {
    @Environment(AppStore.self) private var appStore
    @State private var appeared = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        // Profile header
                        VStack(spacing: HBSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.hbPrimaryLight)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "house.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.hbPrimary)
                            }

                            Text(appStore.currentHome.type.rawValue)
                                .font(HBTypography.h1)
                                .foregroundColor(.hbTextPrimary)

                            // Subscription badge
                            HStack(spacing: HBSpacing.sm) {
                                Image(systemName: appStore.user.subscriptionTier == .premium ? "crown.fill" : "person.fill")
                                    .font(.system(size: 12))
                                Text(appStore.user.subscriptionTier == .premium ? "Premium" : "Member")
                                    .font(HBTypography.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(appStore.user.subscriptionTier == .premium ? .hbElectrical : .hbTextSecondary)
                            .padding(.horizontal, HBSpacing.md)
                            .padding(.vertical, HBSpacing.sm)
                            .background(
                                appStore.user.subscriptionTier == .premium
                                ? Color.hbElectrical.opacity(0.12)
                                : Color.hbBorder.opacity(0.3)
                            )
                            .cornerRadius(HBRadii.chip)
                        }
                        .opacity(appeared ? 1 : 0)

                        // Home Profile section
                        ProfileSection(title: "Home") {
                            ProfileRow(icon: "house.fill", title: "Home Profile", subtitle: appStore.currentHome.name) {
                                HomeProfileView()
                            }
                            ProfileRow(icon: "mappin.circle.fill", title: "Address", subtitle: appStore.currentHome.address ?? "Not set") {
                                EmptyView()
                            }
                        }

                        // Management section
                        ProfileSection(title: "Management") {
                            NavigationLink {
                                ContractorListView()
                            } label: {
                                ProfileRowLabel(icon: "person.2.fill", title: "Contractor Address Book", color: .hbPlumbing)
                            }

                            NavigationLink {
                                ApplianceRegistryView()
                            } label: {
                                ProfileRowLabel(icon: "gearshape.2.fill", title: "Appliance Registry", color: .hbAppliance)
                            }

                            NavigationLink {
                                RemindersListView()
                            } label: {
                                ProfileRowLabel(icon: "bell.fill", title: "Reminders", color: .hbElectrical)
                            }

                            NavigationLink {
                                SeasonalChecklistView()
                            } label: {
                                ProfileRowLabel(icon: "leaf.fill", title: "Seasonal Checklists", color: .hbExterior)
                            }

                            NavigationLink {
                                AchievementsView()
                            } label: {
                                ProfileRowLabel(icon: "trophy.fill", title: "Achievements", color: .hbHVAC)
                            }
                        }

                        // Settings section
                        ProfileSection(title: "Settings") {
                            NavigationLink {
                                NotificationsSettingsView()
                            } label: {
                                ProfileRowLabel(icon: "bell.badge.fill", title: "Notifications", color: .hbDanger)
                            }
                            NavigationLink {
                                SubscriptionView()
                            } label: {
                                ProfileRowLabel(icon: "creditcard.fill", title: "Subscription", color: .hbPrimary)
                            }
                            NavigationLink {
                                ExportDataView()
                            } label: {
                                ProfileRowLabel(icon: "square.and.arrow.up.fill", title: "Export Data (PDF/CSV)", color: .hbStructural)
                            }
                            NavigationLink {
                                ExportDataView()
                            } label: {
                                ProfileRowLabel(icon: "doc.text.fill", title: "Share Home Report", color: .hbExterior)
                            }
                        }

                        // Support section
                        ProfileSection(title: "Support") {
                            NavigationLink {
                                SupportPlaceholderView(title: "Help & Support")
                            } label: {
                                ProfileRowLabel(icon: "questionmark.circle.fill", title: "Help & Support", color: .hbPlumbing)
                            }
                            NavigationLink {
                                SupportPlaceholderView(title: "Privacy Policy")
                            } label: {
                                ProfileRowLabel(icon: "lock.shield.fill", title: "Privacy Policy", color: .hbTextSecondary)
                            }
                            Button(action: { showDeleteAccountAlert = true }) {
                                ProfileRowLabel(icon: "trash.fill", title: "Delete Account", color: .hbDanger)
                            }
                        }

                        // App info
                        VStack(spacing: HBSpacing.xs) {
                            Text("Dwillo v1.0")
                                .font(HBTypography.caption)
                                .foregroundColor(.hbTextSecondary)
                            Text("Made with care for homeowners")
                                .font(HBTypography.caption)
                                .foregroundColor(.hbBorder)
                        }
                        .padding(.top, HBSpacing.md)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, HBSpacing.md)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    // Account deletion would be handled by backend
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
        .onAppear {
            withAnimation(HBAnimation.springGentle) {
                appeared = true
            }
        }
    }
}

// MARK: - Settings Placeholder Screens
struct NotificationsSettingsView: View {
    var body: some View {
        ZStack {
            GradientBackground()
            EmptyStateView(
                icon: "bell.badge.fill",
                title: "Notification Settings",
                subtitle: "Configure when and how you receive reminders"
            )
        }
        .navigationTitle("Notifications")
    }
}

struct SubscriptionView: View {
    var body: some View {
        ZStack {
            GradientBackground()
            EmptyStateView(
                icon: "creditcard.fill",
                title: "Manage Subscription",
                subtitle: "View and manage your Dwillo plan"
            )
        }
        .navigationTitle("Subscription")
    }
}

struct ExportDataView: View {
    var body: some View {
        ZStack {
            GradientBackground()
            EmptyStateView(
                icon: "square.and.arrow.up.fill",
                title: "Export Data",
                subtitle: "Export your maintenance history as PDF or CSV"
            )
        }
        .navigationTitle("Export")
    }
}

struct SupportPlaceholderView: View {
    let title: String
    var body: some View {
        ZStack {
            GradientBackground()
            EmptyStateView(
                icon: "questionmark.circle.fill",
                title: title,
                subtitle: "Content coming soon"
            )
        }
        .navigationTitle(title)
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            Text(title)
                .font(HBTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.hbTextSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, HBSpacing.lg)

            VStack(spacing: 1) {
                content
            }
            .background(Color.hbSurface)
            .cornerRadius(HBRadii.card)
            .padding(.horizontal, HBSpacing.lg)
            .hbShadow(.sm)
        }
    }
}

struct ProfileRow<Destination: View>: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    @ViewBuilder let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            ProfileRowLabel(icon: icon, title: title, subtitle: subtitle)
        }
    }
}

struct ProfileRowLabel: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    var color: Color = .hbPrimary

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }

            Text(title)
                .font(HBTypography.body)
                .foregroundColor(.hbTextPrimary)

            Spacer()

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(HBTypography.bodySmall)
                    .foregroundColor(.hbTextSecondary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.hbBorder)
        }
        .padding(.horizontal, HBSpacing.md)
        .padding(.vertical, HBSpacing.sm + 4)
        .background(Color.hbSurface)
    }
}
