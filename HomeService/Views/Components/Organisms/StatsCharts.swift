import SwiftUI
import Charts

// MARK: - Monthly Spending Bar Chart
struct SpendingBarChart: View {
    let data: [MonthlySpend]

    @State private var appeared = false

    struct MonthlySpend: Identifiable {
        let id = UUID()
        let month: String
        let amount: Double
        let category: HomeCategory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Spending Overview")
                .font(HBTypography.h2)
                .foregroundColor(.hbTextPrimary)

            Chart(data) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", appeared ? item.amount : 0)
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(HBRadii.chartBar)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v))")
                                .font(HBTypography.caption)
                                .foregroundColor(.hbTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .animation(.easeOut(duration: 0.8), value: appeared)
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }

    static let sampleData: [MonthlySpend] = [
        .init(month: "Jan", amount: 320, category: .plumbing),
        .init(month: "Feb", amount: 180, category: .electrical),
        .init(month: "Mar", amount: 450, category: .hvac),
        .init(month: "Apr", amount: 120, category: .exterior),
        .init(month: "May", amount: 280, category: .appliance),
        .init(month: "Jun", amount: 95, category: .structural),
    ]
}

// MARK: - Category Donut Chart
struct CategoryDonutChart: View {
    let data: [CategorySpend]

    struct CategorySpend: Identifiable {
        let id = UUID()
        let category: HomeCategory
        let amount: Double
    }

    var total: Double { max(data.reduce(0) { $0 + $1.amount }, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Category Breakdown")
                .font(HBTypography.h2)
                .foregroundColor(.hbTextPrimary)

            HStack(spacing: HBSpacing.lg) {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.category.color)
                    .cornerRadius(HBRadii.chartBar)
                }
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: HBSpacing.sm) {
                    ForEach(data) { item in
                        HStack(spacing: HBSpacing.sm) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 10, height: 10)
                            Text(item.category.rawValue)
                                .font(HBTypography.bodySmall)
                                .foregroundColor(.hbTextPrimary)
                            Spacer()
                            Text("\(Int(item.amount / total * 100))%")
                                .font(HBTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(.hbTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }

    static let sampleData: [CategorySpend] = [
        .init(category: .plumbing, amount: 850),
        .init(category: .electrical, amount: 420),
        .init(category: .hvac, amount: 1200),
        .init(category: .exterior, amount: 380),
        .init(category: .appliance, amount: 250),
        .init(category: .structural, amount: 180),
    ]
}

// MARK: - Cost Trend Line Chart
struct CostTrendChart: View {
    let data: [MonthlyTotal]

    @State private var appeared = false

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: String
        let total: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Cost Trends")
                .font(HBTypography.h2)
                .foregroundColor(.hbTextPrimary)

            Chart(data) { item in
                LineMark(
                    x: .value("Month", item.month),
                    y: .value("Total", appeared ? item.total : 0)
                )
                .foregroundStyle(Color.hbPrimary)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Month", item.month),
                    y: .value("Total", appeared ? item.total : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.hbPrimary.opacity(0.2), Color.hbPrimary.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", item.month),
                    y: .value("Total", appeared ? item.total : 0)
                )
                .foregroundStyle(Color.hbPrimary)
                .symbolSize(30)
            }
            .frame(height: 180)
            .animation(.easeOut(duration: 1.0), value: appeared)
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                appeared = true
            }
        }
    }

    static let sampleData: [MonthlyTotal] = [
        .init(month: "Jan", total: 320),
        .init(month: "Feb", total: 500),
        .init(month: "Mar", total: 950),
        .init(month: "Apr", total: 1070),
        .init(month: "May", total: 1350),
        .init(month: "Jun", total: 1445),
    ]
}

// MARK: - Maintenance Heatmap (GitHub-style)
struct MaintenanceHeatmap: View {
    let activities: [Date: Int] // date -> count

    private let columns = Array(repeating: GridItem(.fixed(14), spacing: 2), count: 7)
    private let weeks = 26 // ~6 months

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Activity")
                .font(HBTypography.h2)
                .foregroundColor(.hbTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(14), spacing: 2), count: 7), spacing: 2) {
                    ForEach(0..<(weeks * 7), id: \.self) { dayIndex in
                        let date = Calendar.current.date(byAdding: .day, value: -(weeks * 7 - dayIndex), to: Date()) ?? Date()
                        let count = activities[Calendar.current.startOfDay(for: date)] ?? 0

                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatColor(for: count))
                            .frame(width: 14, height: 14)
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(HBTypography.caption)
                    .foregroundColor(.hbTextSecondary)
                ForEach(0...4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(for: level))
                        .frame(width: 14, height: 14)
                }
                Text("More")
                    .font(HBTypography.caption)
                    .foregroundColor(.hbTextSecondary)
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0: return Color.hbBorder.opacity(0.3)
        case 1: return Color.hbPrimary.opacity(0.25)
        case 2: return Color.hbPrimary.opacity(0.5)
        case 3: return Color.hbPrimary.opacity(0.75)
        default: return Color.hbPrimary
        }
    }
}

// MARK: - Contractor Leaderboard
struct ContractorLeaderboard: View {
    let contractors: [ContractorStat]

    struct ContractorStat: Identifiable {
        let id = UUID()
        let name: String
        let specialty: HomeCategory
        let jobCount: Int
        let totalSpend: Double
        let rating: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            Text("Top Contractors")
                .font(HBTypography.h2)
                .foregroundColor(.hbTextPrimary)

            VStack(spacing: HBSpacing.sm) {
                ForEach(contractors) { contractor in
                    HStack(spacing: HBSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(contractor.specialty.color.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: contractor.specialty.icon)
                                .font(.system(size: 18))
                                .foregroundColor(contractor.specialty.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(contractor.name)
                                .font(HBTypography.body)
                                .fontWeight(.medium)
                                .foregroundColor(.hbTextPrimary)
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= contractor.rating ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundColor(.hbElectrical)
                                }
                                Text("• \(contractor.jobCount) jobs")
                                    .font(HBTypography.caption)
                                    .foregroundColor(.hbTextSecondary)
                            }
                        }

                        Spacer()

                        Text("$\(Int(contractor.totalSpend))")
                            .font(HBTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.hbTextPrimary)
                    }
                    .padding(HBSpacing.sm)
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }

    static let sampleData: [ContractorStat] = [
        .init(name: "Mike's Plumbing", specialty: .plumbing, jobCount: 5, totalSpend: 1250, rating: 5),
        .init(name: "Spark Electric Co", specialty: .electrical, jobCount: 3, totalSpend: 680, rating: 4),
        .init(name: "CoolAir HVAC", specialty: .hvac, jobCount: 2, totalSpend: 890, rating: 4),
    ]
}

// MARK: - AI Prediction Card
struct PredictionCard: View {
    let title: String
    let description: String
    let estimatedCost: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(HBTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextPrimary)
                Text(description)
                    .font(HBTypography.bodySmall)
                    .foregroundColor(.hbTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(estimatedCost)
                    .font(HBTypography.body)
                    .fontWeight(.bold)
                    .foregroundColor(.hbDanger)
                HStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("AI")
                        .font(HBTypography.caption)
                }
                .foregroundColor(.hbHVAC)
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .overlay(
            RoundedRectangle(cornerRadius: HBRadii.card)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .hbShadow(.sm)
    }
}
