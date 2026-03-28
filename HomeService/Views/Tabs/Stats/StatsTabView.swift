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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        // Overview cards
                        HStack(spacing: HBSpacing.sm) {
                            MiniStatCard(value: "$\(Int(appStore.totalSpend))", label: "Total Spent", color: .hbPrimary)
                            MiniStatCard(value: "\(appStore.logs.count)", label: "Entries", color: .hbLavender)
                            MiniStatCard(value: "\(appStore.contractors.count)", label: "Contractors", color: .hbSky)
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                        // ML Savings insights
                        let insights = engine.generateSavingsInsights()
                        if !insights.isEmpty {
                            SavingsSection(insights: insights)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 15)
                                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                        }

                        // Cost forecast
                        ForecastChart(forecasts: engine.forecastCosts())
                            .padding(.horizontal, HBSpacing.lg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                        // Category breakdown
                        CategoryDonutChart(data: CategoryDonutChart.sampleData)
                            .padding(.horizontal, HBSpacing.lg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)

                        // Risk assessment
                        let risks = engine.assessCategoryRisks()
                        RiskSection(risks: risks)
                            .padding(.horizontal, HBSpacing.lg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

                        // Spending bar chart
                        SpendingBarChart(data: SpendingBarChart.sampleData)
                            .padding(.horizontal, HBSpacing.lg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.45), value: appeared)

                        // Activity heatmap
                        MaintenanceHeatmap(activities: appStore.activityHeatmap)
                            .padding(.horizontal, HBSpacing.lg)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)

                        // Appliance lifecycle alerts
                        let alerts = engine.applianceAlerts()
                        if !alerts.isEmpty {
                            ApplianceAlertsSection(alerts: alerts)
                                .padding(.horizontal, HBSpacing.lg)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 15)
                                .animation(.easeOut(duration: 0.4).delay(0.55), value: appeared)
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, HBSpacing.sm)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Mini Stat Card
private struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.hbTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }
}

// MARK: - ML Savings Section
private struct SavingsSection: View {
    let insights: [SavingsInsight]

    var totalSavings: Double {
        insights.reduce(0) { $0 + $1.estimatedSavings }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.hbAmber)
                Text("Ways to Save")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.hbTextPrimary)
                Spacer()
                Text("~$\(Int(totalSavings))/yr")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.hbPrimary)
            }
            .padding(.horizontal, HBSpacing.lg)

            ForEach(insights.prefix(3)) { insight in
                HStack(spacing: HBSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(insight.category.color.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: actionIcon(insight.actionType))
                            .font(.system(size: 16))
                            .foregroundColor(insight.category.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.hbTextPrimary)
                        Text(insight.description)
                            .font(.system(size: 12))
                            .foregroundColor(.hbTextSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(Int(insight.estimatedSavings))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.hbPrimary)
                        Text("\(Int(insight.confidence * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.hbTextSecondary)
                    }
                }
                .padding(HBSpacing.sm + 2)
                .background(Color.hbSurface)
                .cornerRadius(12)
                .padding(.horizontal, HBSpacing.lg)
            }
        }
    }

    private func actionIcon(_ type: SavingsInsight.ActionType) -> String {
        switch type {
        case .diy: return "wrench.fill"
        case .bulk: return "shippingbox.fill"
        case .schedule: return "calendar.badge.clock"
        case .prevent: return "shield.checkered"
        case .negotiate: return "person.2.fill"
        }
    }
}

// MARK: - Forecast Chart
private struct ForecastChart: View {
    let forecasts: [CostForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.hbPrimary)
                Text("Cost Forecast")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.hbTextPrimary)
                Spacer()
                Text("ML")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.hbLavender)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.hbLavender.opacity(0.1))
                    .cornerRadius(4)
            }

            Chart {
                ForEach(forecasts) { f in
                    AreaMark(
                        x: .value("Month", f.month),
                        yStart: .value("Lower", f.lowerBound),
                        yEnd: .value("Upper", f.upperBound)
                    )
                    .foregroundStyle(Color.hbPrimary.opacity(0.08))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Month", f.month),
                        y: .value("Predicted", f.predicted)
                    )
                    .foregroundStyle(Color.hbPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", f.month),
                        y: .value("Predicted", f.predicted)
                    )
                    .foregroundStyle(Color.hbPrimary)
                    .symbolSize(20)
                }
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
            .frame(height: 160)
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }
}

// MARK: - Risk Section
private struct RiskSection: View {
    let risks: [CategoryRisk]

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.hbAmber)
                Text("Risk Assessment")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.hbTextPrimary)
            }

            ForEach(risks.prefix(4)) { risk in
                HStack(spacing: HBSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(risk.category.color.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: risk.category.icon)
                            .font(.system(size: 15))
                            .foregroundColor(risk.category.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(risk.category.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.hbTextPrimary)
                        Text(risk.reason)
                            .font(.system(size: 11))
                            .foregroundColor(.hbTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Risk gauge
                    ZStack {
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(Color.hbBorder.opacity(0.2), lineWidth: 3)
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(135))
                        Circle()
                            .trim(from: 0, to: risk.riskScore / 100 * 0.75)
                            .stroke(riskColor(risk.riskScore), lineWidth: 3)
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(135))
                        Text("\(Int(risk.riskScore))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(riskColor(risk.riskScore))
                    }
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }

    private func riskColor(_ score: Double) -> Color {
        if score < 30 { return .hbSuccess }
        if score < 60 { return .hbWarning }
        return .hbDanger
    }
}

// MARK: - Appliance Alerts
private struct ApplianceAlertsSection: View {
    let alerts: [(Appliance, String, Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.hbCoral)
                Text("Appliance Alerts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.hbTextPrimary)
            }

            ForEach(Array(alerts.enumerated()), id: \.offset) { _, alert in
                HStack(spacing: HBSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.hbCoral.opacity(0.08))
                            .frame(width: 36, height: 36)
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.hbCoral)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.0.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.hbTextPrimary)
                        Text(alert.1)
                            .font(.system(size: 11))
                            .foregroundColor(.hbTextSecondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }
}

// MARK: - Home Value (kept from original)
struct HomeValueImpactCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.hbPrimary)
                Text("Home Value Impact").font(HBTypography.h2).foregroundColor(.hbTextPrimary)
                Spacer()
                Text("Premium").font(HBTypography.caption).fontWeight(.semibold).foregroundColor(.hbLavender)
                    .padding(.horizontal, HBSpacing.sm).padding(.vertical, HBSpacing.xs)
                    .background(Color.hbLavender.opacity(0.1)).cornerRadius(HBRadii.badge)
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
