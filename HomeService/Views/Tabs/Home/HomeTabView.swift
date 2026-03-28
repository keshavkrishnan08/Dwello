import SwiftUI

struct HomeTabView: View {
    @Environment(AppStore.self) private var appStore
    @State private var appeared = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var healthLabel: String {
        let s = appStore.homeHealthScore
        if s >= 90 { return "Excellent" }
        if s >= 75 { return "Good Shape" }
        if s >= 60 { return "Needs Attention" }
        return "Critical"
    }

    private var healthSubtitle: String {
        let s = appStore.homeHealthScore
        if s >= 90 { return "Your home is well-maintained" }
        if s >= 75 { return "A few tasks would boost your score" }
        if s >= 60 { return "Several overdue items to address" }
        return "Urgent maintenance needed"
    }

    private var coveredCategories: Int {
        let sixMonths = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return Set(appStore.logs.filter { $0.date > sixMonths }.map(\.category)).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        // Greeting — minimal
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(greeting)
                                    .font(.system(size: 14))
                                    .foregroundColor(.hbTextSecondary)
                                Text(appStore.userName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.hbTextPrimary)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.hbPrimary.opacity(0.08))
                                    .frame(width: 40, height: 40)
                                Text(String(appStore.userName.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.hbPrimary)
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .padding(.top, HBSpacing.md)
                        .opacity(appeared ? 1 : 0)

                        // Health score — animated card
                        VStack(spacing: HBSpacing.md) {
                            ZStack {
                                // Glow background
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.healthScoreColor(for: appStore.homeHealthScore).opacity(0.12), .clear],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 70
                                        )
                                    )
                                    .frame(width: 140, height: 140)

                                HBCircularProgress(
                                    progress: Double(appStore.homeHealthScore) / 100.0,
                                    lineWidth: 10,
                                    size: 110,
                                    color: Color.healthScoreColor(for: appStore.homeHealthScore)
                                )
                            }

                            VStack(spacing: 4) {
                                Text(healthLabel)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.hbTextPrimary)
                                Text(healthSubtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(.hbTextSecondary)
                            }

                            // Mini breakdown
                            HStack(spacing: HBSpacing.lg) {
                                scorePill(icon: "bell.badge", value: "\(appStore.overdueReminders.count)", label: "Overdue", bad: !appStore.overdueReminders.isEmpty)
                                scorePill(icon: "calendar.badge.checkmark", value: "\(appStore.monthlyTaskCount)", label: "This mo.", bad: false)
                                scorePill(icon: "shield.checkered", value: "\(coveredCategories)/6", label: "Coverage", bad: coveredCategories < 3)
                            }
                        }
                        .padding(HBSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.hbPrimary.opacity(0.03), Color.hbLavender.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(Color.hbSurface)
                        .cornerRadius(HBRadii.card)
                        .hbShadow(.sm)
                        .padding(.horizontal, HBSpacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                        // Financial overview — real numbers
                        VStack(spacing: HBSpacing.sm) {
                            HStack(spacing: HBSpacing.sm) {
                                FinStat(
                                    value: "$\(Int(appStore.monthlySpend))",
                                    label: "This Month",
                                    icon: "calendar",
                                    color: .hbPrimary
                                )
                                FinStat(
                                    value: "$\(Int(appStore.totalSpend))",
                                    label: "All Time",
                                    icon: "dollarsign.circle",
                                    color: .hbLavender
                                )
                            }
                            HStack(spacing: HBSpacing.sm) {
                                FinStat(
                                    value: "$\(Int(appStore.projectedAnnualSpend))",
                                    label: "Projected/yr",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .hbAmber
                                )
                                FinStat(
                                    value: "$\(Int(appStore.estimatedSavingsFromPrevention))",
                                    label: "Est. Saved",
                                    icon: "leaf.fill",
                                    color: .hbSuccess
                                )
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                        // Quick log — one-tap common tasks
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            HStack {
                                Text("Quick Log")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.hbTextPrimary)
                                Spacer()
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.hbPrimary)
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HBSpacing.sm) {
                                ForEach(AppStore.quickLogTemplates.prefix(4), id: \.0) { template in
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            appStore.quickLog(title: template.0, category: template.1, cost: template.2)
                                        }
                                    }) {
                                        HStack(spacing: HBSpacing.sm) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(template.1.color.opacity(0.08))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: template.1.icon)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(template.1.color)
                                            }
                                            Text(template.0)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.hbTextPrimary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                        .padding(HBSpacing.sm + 2)
                                        .background(Color.hbSurface)
                                        .cornerRadius(12)
                                        .hbShadow(.sm)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.18), value: appeared)

                        // Overdue alert
                        if !appStore.overdueReminders.isEmpty {
                            HStack(spacing: HBSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.hbDanger)
                                Text("\(appStore.overdueReminders.count) overdue task\(appStore.overdueReminders.count == 1 ? "" : "s")")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.hbDanger)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.hbDanger.opacity(0.5))
                            }
                            .padding(HBSpacing.sm + 4)
                            .background(Color.hbDanger.opacity(0.06))
                            .cornerRadius(10)
                            .padding(.horizontal, HBSpacing.lg)
                        }

                        // Upcoming maintenance
                        if !appStore.upcomingReminders.isEmpty {
                            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                                Text("Upcoming")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.hbTextPrimary)
                                    .padding(.horizontal, HBSpacing.lg)

                                ForEach(appStore.upcomingReminders.prefix(3)) { reminder in
                                    HStack(spacing: HBSpacing.md) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(reminder.category.color)
                                            .frame(width: 4, height: 36)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reminder.title)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.hbTextPrimary)
                                                .lineLimit(1)
                                            Text(reminder.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                                                .font(.system(size: 12))
                                                .foregroundColor(reminder.isOverdue ? .hbDanger : .hbTextSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, HBSpacing.lg)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                        }

                        // Recent activity
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            HStack {
                                Text("Recent")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.hbTextPrimary)
                                Spacer()
                                NavigationLink("See all") { AllLogsView() }
                                    .font(.system(size: 13)).foregroundColor(.hbPrimary)
                            }

                            if appStore.recentLogs.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: HBSpacing.sm) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 24))
                                            .foregroundColor(.hbBorder)
                                        Text("No entries yet")
                                            .font(.system(size: 13))
                                            .foregroundColor(.hbTextSecondary)
                                    }
                                    .padding(.vertical, HBSpacing.xl)
                                    Spacer()
                                }
                            } else {
                                ForEach(appStore.recentLogs.prefix(4)) { entry in
                                    NavigationLink {
                                        LogDetailView(entry: entry)
                                    } label: {
                                        HStack(spacing: HBSpacing.md) {
                                            Circle()
                                                .fill(entry.category.color.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Image(systemName: entry.category.icon)
                                                        .font(.system(size: 15))
                                                        .foregroundColor(entry.category.color)
                                                )
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(entry.title)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.hbTextPrimary)
                                                    .lineLimit(1)
                                                Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.hbTextSecondary)
                                            }
                                            Spacer()
                                            if let cost = entry.cost, cost > 0 {
                                                Text("$\(Int(cost))")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.hbTextPrimary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    @ViewBuilder
    private func scorePill(icon: String, value: String, label: String, bad: Bool) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(bad ? .hbDanger : .hbPrimary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(bad ? .hbDanger : .hbTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.hbTextSecondary)
        }
    }
}

private struct FinStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: HBSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.hbTextPrimary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.hbTextSecondary)
            }
            Spacer()
        }
        .padding(HBSpacing.sm + 2)
        .frame(maxWidth: .infinity)
        .background(Color.hbSurface)
        .cornerRadius(12)
    }
}

struct HomeHealthScoreCard: View {
    let score: Int
    var body: some View {
        HStack(spacing: HBSpacing.lg) {
            HBCircularProgress(progress: Double(score) / 100.0, lineWidth: 10, size: 100,
                               color: Color.healthScoreColor(for: score))
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                Text("Home Health").font(HBTypography.h2).foregroundColor(.hbTextPrimary)
                Text(score >= 80 ? "Your home is in great shape." : "Some tasks are overdue.")
                    .font(HBTypography.bodySmall).foregroundColor(.hbTextSecondary).lineLimit(2)
            }
        }.padding(HBSpacing.lg).background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
}
