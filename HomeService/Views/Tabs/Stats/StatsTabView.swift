import SwiftUI
import Charts

struct StatsTabView: View {
    @Environment(AppStore.self) private var appStore
    @State private var appeared = false

    private var engine: MaintenanceMLEngine {
        MaintenanceMLEngine(logs: appStore.logs, appliances: appStore.appliances)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                if appStore.logs.isEmpty {
                    VStack(spacing: HBSpacing.md) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 40))
                            .foregroundColor(.hbBorder)
                        Text("No data yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.hbTextPrimary)
                        Text("Log your first maintenance task\nto see statistics here")
                            .font(.system(size: 14))
                            .foregroundColor(.hbTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HBSpacing.lg) {
                            // Overview cards
                            HStack(spacing: HBSpacing.sm) {
                                MiniStatCard(value: "$\(Int(appStore.totalSpend))", label: "Total Spent", color: .hbPrimary)
                                MiniStatCard(value: "\(appStore.logs.count)", label: "Entries", color: .hbLavender)
                                MiniStatCard(value: "$\(Int(appStore.avgCostPerEntry))", label: "Avg Cost", color: .hbAmber)
                            }
                            .padding(.horizontal, HBSpacing.lg)
                            .opacity(appeared ? 1 : 0)

                            // Monthly spending bar chart — from real data
                            if appStore.spendByMonth.contains(where: { $0.1 > 0 }) {
                                RealSpendingChart(data: appStore.spendByMonth)
                                    .padding(.horizontal, HBSpacing.lg)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
                            }

                            // Category pie chart — from real data
                            if !appStore.categoryBreakdown.isEmpty {
                                RealCategoryChart(data: appStore.categoryBreakdown, logCounts: appStore.categoryLogCounts)
                                    .padding(.horizontal, HBSpacing.lg)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
                            }

                            // Risk assessment — from real data
                            let risks = engine.assessCategoryRisks()
                            if !risks.isEmpty {
                                RiskSection(risks: risks)
                                    .padding(.horizontal, HBSpacing.lg)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
                            }

                            // Cost forecast — from real data
                            let forecasts = engine.forecastCosts()
                            if !forecasts.isEmpty {
                                ForecastChart(forecasts: forecasts)
                                    .padding(.horizontal, HBSpacing.lg)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.45), value: appeared)
                            }

                            // Savings insights — from real data
                            let insights = engine.generateSavingsInsights()
                            if !insights.isEmpty {
                                SavingsSection(insights: insights)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.55), value: appeared)
                            }

                            // Activity heatmap — from real data
                            if !appStore.activityHeatmap.isEmpty {
                                MaintenanceHeatmap(activities: appStore.activityHeatmap)
                                    .padding(.horizontal, HBSpacing.lg)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.65), value: appeared)
                            }

                            // Appliance alerts — from real data
                            let alerts = engine.applianceAlerts()
                            if !alerts.isEmpty {
                                ApplianceAlertsSection(alerts: alerts)
                                    .padding(.horizontal, HBSpacing.lg)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.easeOut(duration: 0.4).delay(0.75), value: appeared)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.top, HBSpacing.sm)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Mini Stat Card
private struct MiniStatCard: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.hbTextSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, HBSpacing.md)
        .background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
}

// MARK: - Real Monthly Spending Chart
private struct RealSpendingChart: View {
    let data: [(String, Double)]
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Monthly Spending")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.hbTextPrimary)

            Chart(Array(data.enumerated()), id: \.offset) { _, item in
                BarMark(
                    x: .value("Month", item.0),
                    y: .value("Amount", appeared ? item.1 : 0)
                )
                .foregroundStyle(Color.hbPrimary.gradient)
                .cornerRadius(HBRadii.chartBar)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { val in
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text("$\(Int(v))").font(.system(size: 10)).foregroundColor(.hbTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .animation(.easeOut(duration: 0.8), value: appeared)
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
        .onAppear { withAnimation(.easeOut(duration: 0.8).delay(0.2)) { appeared = true } }
    }
}

// MARK: - Real Category Breakdown (Donut)
private struct RealCategoryChart: View {
    let data: [(HomeCategory, Double)]
    let logCounts: [(HomeCategory, Int)]

    var total: Double { max(data.reduce(0) { $0 + $1.1 }, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Category Breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.hbTextPrimary)

            HStack(spacing: HBSpacing.lg) {
                Chart(Array(data.enumerated()), id: \.offset) { _, item in
                    SectorMark(
                        angle: .value("Amount", item.1),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.0.color)
                    .cornerRadius(HBRadii.chartBar)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    ForEach(Array(data.prefix(5).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: HBSpacing.sm) {
                            Circle().fill(item.0.color).frame(width: 8, height: 8)
                            Text(item.0.rawValue)
                                .font(.system(size: 13)).foregroundColor(.hbTextPrimary)
                            Spacer()
                            Text("$\(Int(item.1))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.hbTextSecondary)
                        }
                    }
                }
            }

            // Log count per category
            HStack(spacing: HBSpacing.sm) {
                ForEach(Array(logCounts.prefix(4).enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 3) {
                        Image(systemName: item.0.icon).font(.system(size: 10)).foregroundColor(item.0.color)
                        Text("\(item.1)").font(.system(size: 12, weight: .semibold)).foregroundColor(.hbTextPrimary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(item.0.color.opacity(0.06)).cornerRadius(8)
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
}

// MARK: - Risk Section
private struct RiskSection: View {
    let risks: [CategoryRisk]
    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.hbAmber)
                Text("Risk Assessment").font(.system(size: 18, weight: .semibold)).foregroundColor(.hbTextPrimary)
            }
            ForEach(risks.prefix(4)) { risk in
                HStack(spacing: HBSpacing.md) {
                    ZStack {
                        Circle().fill(risk.category.color.opacity(0.1)).frame(width: 36)
                        Image(systemName: risk.category.icon).font(.system(size: 15)).foregroundColor(risk.category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(risk.category.rawValue).font(.system(size: 14, weight: .medium)).foregroundColor(.hbTextPrimary)
                        Text(risk.reason).font(.system(size: 11)).foregroundColor(.hbTextSecondary).lineLimit(1)
                    }
                    Spacer()
                    ZStack {
                        Circle().trim(from: 0, to: 0.75).stroke(Color.hbBorder.opacity(0.2), lineWidth: 3).frame(width: 30).rotationEffect(.degrees(135))
                        Circle().trim(from: 0, to: risk.riskScore / 100 * 0.75).stroke(riskColor(risk.riskScore), lineWidth: 3).frame(width: 30).rotationEffect(.degrees(135))
                        Text("\(Int(risk.riskScore))").font(.system(size: 9, weight: .bold)).foregroundColor(riskColor(risk.riskScore))
                    }
                }
            }
        }
        .padding(HBSpacing.md).background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
    private func riskColor(_ s: Double) -> Color {
        s < 30 ? .hbSuccess : s < 60 ? .hbWarning : .hbDanger
    }
}

// MARK: - Forecast Chart
private struct ForecastChart: View {
    let forecasts: [CostForecast]
    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.hbPrimary)
                Text("Cost Forecast").font(.system(size: 18, weight: .semibold)).foregroundColor(.hbTextPrimary)
            }
            Chart {
                ForEach(forecasts) { f in
                    AreaMark(x: .value("Mo", f.month), yStart: .value("Lo", f.lowerBound), yEnd: .value("Hi", f.upperBound))
                        .foregroundStyle(Color.hbPrimary.opacity(0.08)).interpolationMethod(.catmullRom)
                    LineMark(x: .value("Mo", f.month), y: .value("$", f.predicted))
                        .foregroundStyle(Color.hbPrimary).lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Mo", f.month), y: .value("$", f.predicted))
                        .foregroundStyle(Color.hbPrimary).symbolSize(20)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { val in
                    AxisValueLabel {
                        if let v = val.as(Double.self) { Text("$\(Int(v))").font(.system(size: 10)).foregroundColor(.hbTextSecondary) }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(HBSpacing.md).background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
}

// MARK: - Savings Section
private struct SavingsSection: View {
    let insights: [SavingsInsight]
    var totalSavings: Double { insights.reduce(0) { $0 + $1.estimatedSavings } }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundColor(.hbAmber)
                Text("Ways to Save").font(.system(size: 18, weight: .semibold)).foregroundColor(.hbTextPrimary)
                Spacer()
                Text("~$\(Int(totalSavings))/yr").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.hbPrimary)
            }.padding(.horizontal, HBSpacing.lg)

            ForEach(insights.prefix(3)) { insight in
                HStack(spacing: HBSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(insight.category.color.opacity(0.08)).frame(width: 40, height: 40)
                        Image(systemName: actionIcon(insight.actionType)).font(.system(size: 16)).foregroundColor(insight.category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.hbTextPrimary)
                        Text(insight.description).font(.system(size: 12)).foregroundColor(.hbTextSecondary).lineLimit(2)
                    }
                    Spacer()
                    Text("$\(Int(insight.estimatedSavings))").font(.system(size: 14, weight: .bold)).foregroundColor(.hbPrimary)
                }
                .padding(HBSpacing.sm + 2).background(Color.hbSurface).cornerRadius(12)
                .padding(.horizontal, HBSpacing.lg)
            }
        }
    }
    private func actionIcon(_ t: SavingsInsight.ActionType) -> String {
        switch t { case .diy: return "wrench.fill"; case .bulk: return "shippingbox.fill"; case .schedule: return "calendar.badge.clock"; case .prevent: return "shield.checkered"; case .negotiate: return "person.2.fill" }
    }
}

// MARK: - Appliance Alerts
private struct ApplianceAlertsSection: View {
    let alerts: [(Appliance, String, Double)]
    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "gearshape.fill").foregroundColor(.hbCoral)
                Text("Appliance Alerts").font(.system(size: 18, weight: .semibold)).foregroundColor(.hbTextPrimary)
            }
            ForEach(Array(alerts.enumerated()), id: \.offset) { _, alert in
                HStack(spacing: HBSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color.hbCoral.opacity(0.08)).frame(width: 36, height: 36)
                        Image(systemName: "exclamationmark.circle.fill").font(.system(size: 16)).foregroundColor(.hbCoral)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.0.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.hbTextPrimary)
                        Text(alert.1).font(.system(size: 11)).foregroundColor(.hbTextSecondary).lineLimit(2)
                    }
                }
            }
        }
        .padding(HBSpacing.md).background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
}

// MARK: - Home Value (kept)
struct HomeValueImpactCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.hbPrimary)
                Text("Home Value Impact").font(HBTypography.h2).foregroundColor(.hbTextPrimary)
            }
            HStack(spacing: HBSpacing.lg) {
                VStack(alignment: .leading, spacing: HBSpacing.xs) {
                    Text("Value Protected").font(HBTypography.caption).foregroundColor(.hbTextSecondary)
                    Text("$24,500").font(HBTypography.statSmall).foregroundColor(.hbPrimary)
                }
                Divider().frame(height: 40)
                VStack(alignment: .leading, spacing: HBSpacing.xs) {
                    Text("ROI on Maintenance").font(HBTypography.caption).foregroundColor(.hbTextSecondary)
                    Text("4.2x").font(HBTypography.statSmall).foregroundColor(.hbSuccess)
                }
            }
        }
        .padding(HBSpacing.md).background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
    }
}
