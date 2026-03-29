import SwiftUI

struct HomeTabView: View {
    @Environment(AppStore.self) private var appStore
    @State private var appeared = false
    @State private var showAddQuickLog = false
    @Environment(\.horizontalSizeClass) private var sizeClass

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
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(greeting)
                                    .font(.system(size: 14))
                                    .foregroundColor(.hbTextSecondary)
                                Text("My Home")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.hbTextPrimary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .padding(.top, HBSpacing.md)
                        .opacity(appeared ? 1 : 0)

                        // Health score card with breakdown
                        VStack(spacing: HBSpacing.md) {
                            HStack(spacing: HBSpacing.lg) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [Color.healthScoreColor(for: appStore.homeHealthScore).opacity(0.1), .clear],
                                                center: .center,
                                                startRadius: 8,
                                                endRadius: 55
                                            )
                                        )
                                        .frame(width: 110, height: 110)

                                    HBCircularProgress(
                                        progress: Double(appStore.homeHealthScore) / 100.0,
                                        lineWidth: 8,
                                        size: 90,
                                        color: Color.healthScoreColor(for: appStore.homeHealthScore)
                                    )
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Home Health")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.hbTextSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    Text(healthLabel)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.hbTextPrimary)
                                    Text(healthSubtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(.hbTextSecondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }

                            // Score breakdown — what's helping/hurting
                            let breakdown = appStore.homeHealthBreakdown
                            if !breakdown.isEmpty {
                                VStack(spacing: 6) {
                                    ForEach(breakdown.prefix(4)) { item in
                                        HStack(spacing: HBSpacing.sm) {
                                            Image(systemName: item.impact >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                                .font(.system(size: 13))
                                                .foregroundColor(itemColor(item))
                                            Text(item.label)
                                                .font(.system(size: 13))
                                                .foregroundColor(.hbTextSecondary)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(item.impact >= 0 ? "+\(item.impact)" : "\(item.impact)")
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundColor(itemColor(item))
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(HBSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(Color.hbSurface)
                        .cornerRadius(HBRadii.card)
                        .hbShadow(.sm)
                        .padding(.horizontal, HBSpacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                        // Financial overview — all from real data
                        if !appStore.logs.isEmpty {
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
                        }

                        // Quick log — example + add custom
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            HStack {
                                Text("Quick Log")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.hbTextPrimary)
                                Spacer()
                            }

                            // Show user's custom quick logs or one example
                            if appStore.customQuickLogs.isEmpty {
                                // One example
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    appStore.quickLog(title: "Changed HVAC filter", category: .hvac, cost: 25)
                                }) {
                                    HStack(spacing: HBSpacing.sm) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.hbPrimary.opacity(0.08))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: "thermometer.medium")
                                                .font(.system(size: 14))
                                                .foregroundColor(.hbPrimary)
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Changed HVAC filter")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.hbTextPrimary)
                                            Text("$25 · HVAC")
                                                .font(.system(size: 11))
                                                .foregroundColor(.hbTextSecondary)
                                        }
                                        Spacer()
                                        Text("Tap to log")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.hbPrimary)
                                    }
                                    .padding(HBSpacing.sm + 2)
                                    .background(Color.hbSurface)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            } else {
                                ForEach(appStore.customQuickLogs, id: \.title) { ql in
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        appStore.quickLog(title: ql.title, category: ql.category, cost: ql.cost)
                                    }) {
                                        HStack(spacing: HBSpacing.sm) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(ql.category.color.opacity(0.08))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: ql.category.icon)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(ql.category.color)
                                            }
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(ql.title)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.hbTextPrimary)
                                                if let cost = ql.cost, cost > 0 {
                                                    Text("$\(Int(cost)) · \(ql.category.rawValue)")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.hbTextSecondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(HBSpacing.sm + 2)
                                        .background(Color.hbSurface)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }

                            // Add custom quick log button
                            Button(action: { showAddQuickLog = true }) {
                                HStack(spacing: HBSpacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.hbPrimary)
                                    Text("Create quick log shortcut")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.hbPrimary)
                                    Spacer()
                                }
                                .padding(HBSpacing.sm + 2)
                                .background(Color.hbPrimary.opacity(0.04))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.hbPrimary.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
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
            .sheet(isPresented: $showAddQuickLog) {
                AddQuickLogSheet(appStore: appStore)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    private func itemColor(_ item: ScoreComponent) -> Color {
        switch item.type {
        case .positive: return .hbPrimary
        case .negative: return .hbDanger
        case .warning: return .hbAmber
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

// MARK: - Add Quick Log Sheet
struct AddQuickLogSheet: View {
    let appStore: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category: HomeCategory = .hvac
    @State private var cost = ""

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            RoundedRectangle(cornerRadius: 3).fill(Color.hbBorder).frame(width: 36, height: 5)
                .padding(.top, HBSpacing.sm)

            Text("New Quick Log")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.hbTextPrimary)

            VStack(spacing: HBSpacing.md) {
                HBTextField(title: "Task name", text: $title, placeholder: "e.g., Changed HVAC filter", icon: "wrench.fill")

                CategoryChipSelector(selected: $category)

                HBCurrencyField(title: "Cost (optional)", value: $cost)
            }
            .padding(.horizontal, HBSpacing.lg)

            Spacer()

            VStack(spacing: HBSpacing.sm) {
                HBButton(title: "Save & Log Now", isEnabled: isValid) {
                    let parsedCost = Double(cost.replacingOccurrences(of: ",", with: ""))
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    appStore.addQuickLogShortcut(title: trimmed, category: category, cost: parsedCost)
                    appStore.quickLog(title: trimmed, category: category, cost: parsedCost)
                    dismiss()
                }

                HBButton(title: "Save Shortcut Only", style: .secondary, isEnabled: isValid) {
                    let parsedCost = Double(cost.replacingOccurrences(of: ",", with: ""))
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    appStore.addQuickLogShortcut(title: trimmed, category: category, cost: parsedCost)
                    dismiss()
                }
            }
            .padding(.horizontal, HBSpacing.lg)
            .padding(.bottom, HBSpacing.lg)
        }
    }
}
