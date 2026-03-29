import Foundation

struct SavingsInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let estimatedSavings: Double
    let category: HomeCategory
    let confidence: Double // 0–1
    let actionType: ActionType

    enum ActionType: String {
        case diy = "DIY"
        case bulk = "Bulk Buy"
        case schedule = "Schedule"
        case prevent = "Prevent"
        case negotiate = "Negotiate"
    }
}

struct CostForecast: Identifiable {
    let id = UUID()
    let month: String
    let predicted: Double
    let lowerBound: Double
    let upperBound: Double
}

struct CategoryRisk: Identifiable {
    let id = UUID()
    let category: HomeCategory
    let riskScore: Double // 0–100
    let reason: String
    let daysUntilLikely: Int?
}

class MaintenanceMLEngine {
    private let logs: [LogEntry]
    private let appliances: [Appliance]
    private let homeAge: Int?

    init(logs: [LogEntry], appliances: [Appliance], homeAge: Int? = nil) {
        self.logs = logs
        self.appliances = appliances
        self.homeAge = homeAge
    }

    // MARK: - Savings Analysis

    func generateSavingsInsights() -> [SavingsInsight] {
        guard logs.count >= 2 else { return [] }

        var insights: [SavingsInsight] = []

        // 1. Detect recurring high-cost categories
        let categorySpend = Dictionary(grouping: logs, by: \.category)
            .mapValues { entries in entries.compactMap(\.cost).reduce(0, +) }

        if let topCategory = categorySpend.max(by: { $0.value < $1.value }), topCategory.value > 0 {
            insights.append(SavingsInsight(
                title: "High \(topCategory.key.rawValue) spending",
                description: "You've spent $\(Int(topCategory.value)) on \(topCategory.key.rawValue.lowercased()). Consider preventive maintenance to reduce emergency calls.",
                estimatedSavings: topCategory.value * 0.25,
                category: topCategory.key,
                confidence: 0.78,
                actionType: .prevent
            ))
        }

        // 2. DIY opportunity detection
        let lowCostEntries = logs.filter { ($0.cost ?? 0) < 100 && ($0.cost ?? 0) > 0 }
        if lowCostEntries.count > 2 {
            let totalLowCost = lowCostEntries.compactMap(\.cost).reduce(0, +)
            insights.append(SavingsInsight(
                title: "DIY opportunity",
                description: "\(lowCostEntries.count) tasks under $100 could be DIY. Watch tutorials and save on labor.",
                estimatedSavings: totalLowCost * 0.6,
                category: lowCostEntries.first?.category ?? .other,
                confidence: 0.65,
                actionType: .diy
            ))
        }

        // 3. Bulk purchase detection (recurring same-category tasks)
        let hvacLogs = logs.filter { $0.category == .hvac }
        if hvacLogs.count >= 3 {
            insights.append(SavingsInsight(
                title: "Buy HVAC filters in bulk",
                description: "You change filters regularly. A 6-pack saves ~40% vs individual purchases.",
                estimatedSavings: 85,
                category: .hvac,
                confidence: 0.92,
                actionType: .bulk
            ))
        }

        // 4. Seasonal scheduling optimization
        let springLogs = logs.filter {
            Calendar.current.component(.month, from: $0.date).isBetween(3, and: 5)
        }
        let fallLogs = logs.filter {
            Calendar.current.component(.month, from: $0.date).isBetween(9, and: 11)
        }
        if springLogs.isEmpty || fallLogs.isEmpty {
            insights.append(SavingsInsight(
                title: "Schedule seasonal checkups",
                description: "Twice-yearly inspections catch small problems before they become expensive repairs.",
                estimatedSavings: 500,
                category: .structural,
                confidence: 0.85,
                actionType: .schedule
            ))
        }

        // 5. Contractor negotiation
        let contractorJobs = logs.filter { $0.contractorId != nil }
        if contractorJobs.count >= 3 {
            let avgContractorCost = contractorJobs.compactMap(\.cost).reduce(0, +) / Double(contractorJobs.count)
            insights.append(SavingsInsight(
                title: "Bundle contractor visits",
                description: "Combining multiple tasks per visit reduces call-out fees. Average job: $\(Int(avgContractorCost)).",
                estimatedSavings: avgContractorCost * 0.15 * Double(contractorJobs.count),
                category: contractorJobs.first?.category ?? .other,
                confidence: 0.72,
                actionType: .negotiate
            ))
        }

        return insights.sorted { $0.estimatedSavings > $1.estimatedSavings }
    }

    // MARK: - Cost Forecasting (Linear regression + seasonality)

    func forecastCosts(months: Int = 6) -> [CostForecast] {
        let monthlySpend = computeMonthlySpend()
        // Need at least 2 months of data for any forecast
        guard monthlySpend.count >= 2 else { return [] }

        // Simple linear regression
        let n = Double(monthlySpend.count)
        let xs = (0..<monthlySpend.count).map { Double($0) }
        let ys = monthlySpend.map(\.1)
        let xMean = xs.reduce(0, +) / n
        let yMean = ys.reduce(0, +) / n
        let slope = zip(xs, ys).map { ($0 - xMean) * ($1 - yMean) }.reduce(0, +)
            / max(xs.map { pow($0 - xMean, 2) }.reduce(0, +), 0.001)
        let intercept = yMean - slope * xMean

        // Compute residual std dev for confidence interval
        let residuals = zip(xs, ys).map { $1 - (slope * $0 + intercept) }
        let stdDev = sqrt(residuals.map { $0 * $0 }.reduce(0, +) / max(n - 2, 1))

        return (0..<months).map { i in
            let x = n + Double(i)
            let predicted = max(0, slope * x + intercept)
            let date = Calendar.current.date(byAdding: .month, value: i + 1, to: Date()) ?? Date()
            return CostForecast(
                month: date.formatted(.dateTime.month(.abbreviated)),
                predicted: predicted,
                lowerBound: max(0, predicted - 1.5 * stdDev),
                upperBound: predicted + 1.5 * stdDev
            )
        }
    }

    // MARK: - Risk Assessment

    func assessCategoryRisks() -> [CategoryRisk] {
        // Only assess categories the user has actually logged
        let loggedCategories = Set(logs.map(\.category))
        guard !loggedCategories.isEmpty else { return [] }

        var risks: [CategoryRisk] = []

        for category in loggedCategories where category != .other {
            let catLogs = logs.filter { $0.category == category }
            guard !catLogs.isEmpty else { continue }

            guard let lastDate = catLogs.map(\.date).max() else { continue }
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

            // Risk increases with time since last maintenance
            var risk = min(100, Double(daysSince) / 3.65) // 365 days = 100 risk
            let avgCost = catLogs.compactMap(\.cost).reduce(0, +) / Double(max(catLogs.count, 1))
            if avgCost > 200 { risk = min(100, risk * 1.2) }

            let reason: String
            if daysSince > 180 { reason = "Last serviced \(daysSince) days ago — overdue" }
            else if daysSince > 90 { reason = "Due for routine check — \(daysSince) days since last" }
            else { reason = "Recently maintained — good shape" }

            risks.append(CategoryRisk(
                category: category,
                riskScore: risk,
                reason: reason,
                daysUntilLikely: max(0, 180 - daysSince)
            ))
        }

        return risks.sorted { $0.riskScore > $1.riskScore }
    }

    // MARK: - Appliance Lifecycle

    func applianceAlerts() -> [(Appliance, String, Double)] {
        let lifespans: [String: Double] = [
            "Dishwasher": 10, "Washer": 11, "Dryer": 13, "Water Heater": 10,
            "HVAC System": 15, "Refrigerator": 14, "Oven": 15, "Microwave": 9,
            "Garbage Disposal": 12, "Furnace": 18,
        ]
        return appliances.compactMap { appliance in
            guard let purchaseDate = appliance.purchaseDate else { return nil }
            let ageYears = Double(Calendar.current.dateComponents([.year], from: purchaseDate, to: Date()).year ?? 0)
            let expectedLife = lifespans[appliance.name] ?? 12
            let urgency = ageYears / expectedLife

            if urgency > 0.75 {
                return (appliance, "\(appliance.name) is \(Int(ageYears)) years old (expected lifespan: \(Int(expectedLife))). Start budgeting for replacement.", urgency)
            }
            return nil
        }
    }

    // MARK: - Helpers

    private func computeMonthlySpend() -> [(Date, Double)] {
        let grouped = Dictionary(grouping: logs) { entry in
            Calendar.current.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
        }
        return grouped.map { ($0.key, $0.value.compactMap(\.cost).reduce(0, +)) }
            .sorted { $0.0 < $1.0 }
    }
}

private extension Int {
    func isBetween(_ a: Int, and b: Int) -> Bool {
        return self >= a && self <= b
    }
}
