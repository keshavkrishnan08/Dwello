import Foundation

/// Knows the recommended maintenance intervals for every task type.
/// When a user logs a task, this figures out when they should do it next.
struct MaintenanceScheduler {

    /// Recommended interval in days for common tasks, by keyword matching.
    /// Based on NAHB, HVAC manufacturer, and home inspector guidelines.
    private static let taskIntervals: [(keywords: [String], days: Int, category: HomeCategory?)] = [
        // HVAC — most time-sensitive
        (["hvac filter", "ac filter", "air filter", "furnace filter"], 30, .hvac),
        (["ac tune", "hvac tune", "hvac service", "ac service", "furnace service"], 365, .hvac),
        (["thermostat", "replaced thermostat"], 1825, .hvac),     // 5 years
        (["duct clean", "duct inspection"], 1095, .hvac),          // 3 years

        // Plumbing
        (["water heater flush", "flush water heater", "water heater anode", "anode rod"], 365, .plumbing),
        (["faucet", "leak", "drip"], 180, .plumbing),
        (["toilet", "flapper", "fill valve"], 365, .plumbing),
        (["garbage disposal"], 365, .plumbing),
        (["sump pump"], 90, .plumbing),

        // Electrical
        (["smoke detector", "smoke alarm", "co detector", "carbon monoxide"], 180, .electrical),
        (["outlet", "gfci", "switch"], 1825, .electrical),        // 5 years
        (["light bulb", "light fixture"], 365, .electrical),
        (["panel", "breaker", "electrical panel"], 1825, .electrical),

        // Exterior
        (["gutter", "downspout"], 180, .exterior),
        (["pressure wash", "power wash"], 365, .exterior),
        (["lawn", "mow", "mowed"], 14, .exterior),
        (["tree", "trim", "branch", "pruning"], 365, .exterior),
        (["deck", "stain", "seal deck"], 730, .exterior),          // 2 years
        (["fence"], 730, .exterior),
        (["driveway", "walkway"], 365, .exterior),

        // Appliance
        (["dishwasher", "dishwasher filter", "dishwasher clean"], 90, .appliance),
        (["refrigerator coil", "fridge coil", "fridge clean"], 180, .appliance),
        (["dryer vent", "dryer lint", "lint trap"], 90, .appliance),
        (["washer clean", "washing machine"], 90, .appliance),
        (["oven clean"], 90, .appliance),

        // Structural
        (["roof", "shingle", "roof inspect"], 365, .structural),
        (["drywall", "patch", "wall repair"], 730, .structural),
        (["caulk", "window seal", "weather strip"], 365, .structural),
        (["foundation", "crack", "basement"], 365, .structural),
        (["insulation", "attic"], 1095, .structural),              // 3 years
        (["paint", "repaint", "touch up paint"], 1095, .structural),
    ]

    /// Default intervals by category when no keyword match is found.
    private static let categoryDefaults: [HomeCategory: Int] = [
        .hvac: 90,
        .plumbing: 180,
        .electrical: 365,
        .exterior: 180,
        .appliance: 90,
        .structural: 365,
        .other: 180,
    ]

    /// Given a logged task title and category, returns the recommended next check-in date.
    static func nextCheckIn(for title: String, category: HomeCategory, from date: Date = Date()) -> Date {
        let lower = title.lowercased()
        let days = matchInterval(title: lower, category: category)
        return Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Returns the interval in days and a human-readable label.
    static func recommendedInterval(for title: String, category: HomeCategory) -> (days: Int, label: String) {
        let days = matchInterval(title: title.lowercased(), category: category)
        return (days, labelFor(days: days))
    }

    /// Estimate annual cost for a task based on its interval and single cost.
    static func annualCost(singleCost: Double, intervalDays: Int) -> Double {
        guard intervalDays > 0 else { return singleCost }
        return singleCost * (365.0 / Double(intervalDays))
    }

    // MARK: - Private

    private static func matchInterval(title: String, category: HomeCategory) -> Int {
        // Try keyword match first
        for rule in taskIntervals {
            if rule.keywords.contains(where: { title.contains($0) }) {
                return rule.days
            }
        }
        // Fall back to category default
        return categoryDefaults[category] ?? 180
    }

    private static func labelFor(days: Int) -> String {
        switch days {
        case 0..<21: return "Every \(days) days"
        case 21..<45: return "Monthly"
        case 45..<100: return "Every 3 months"
        case 100..<200: return "Every 6 months"
        case 200..<400: return "Yearly"
        case 400..<800: return "Every 2 years"
        case 800..<1200: return "Every 3 years"
        default: return "Every \(days / 365) years"
        }
    }
}
