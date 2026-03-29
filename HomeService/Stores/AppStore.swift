import SwiftUI

@Observable
class AppStore {
    // MARK: - User
    var user: HBUser = .sample
    var userName: String { user.name.isEmpty ? "Homeowner" : user.name }

    // MARK: - Home
    var currentHome: Home = .sample

    // MARK: - Core Data
    var logs: [LogEntry] = [] {
        didSet { save() }
    }
    var contractors: [Contractor] = [] {
        didSet { save() }
    }
    var reminders: [Reminder] = [] {
        didSet { save() }
    }
    var appliances: [Appliance] = [] {
        didSet { save() }
    }
    var achievements: [Achievement] = []

    // MARK: - Init
    init() {
        load()
        applyOnboardingResponses()
        refreshAchievements()
    }

    private func applyOnboardingResponses() {
        guard let responses = OnboardingStore.loadResponses() else { return }
        if let homeType = responses.homeType {
            currentHome = Home(
                id: currentHome.id,
                userId: currentHome.userId,
                name: currentHome.name,
                type: homeType,
                yearBuilt: yearFromAge(responses.homeAge),
                sqft: currentHome.sqft,
                address: currentHome.address
            )
        }
    }

    private func yearFromAge(_ age: OnboardingResponses.HomeAge?) -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        switch age {
        case .newBuild: return currentYear - 2
        case .established: return currentYear - 12
        case .mature: return currentYear - 35
        case .historic: return currentYear - 60
        case .none: return currentYear - 15
        }
    }

    // MARK: - Computed Properties

    var recentLogs: [LogEntry] {
        logs.sorted { $0.date > $1.date }
    }

    var homeHealthScore: Int {
        let result = computeScore()
        return result.0
    }

    var homeHealthBreakdown: [ScoreComponent] {
        computeScore().1
    }

    var monthlySpend: Double {
        logs.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }.compactMap(\.cost).reduce(0, +)
    }

    var totalSpend: Double {
        logs.compactMap(\.cost).reduce(0, +)
    }

    var monthlyTaskCount: Int {
        logs.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }.count
    }

    var daysSinceLastService: Int {
        guard let latest = logs.map(\.date).max() else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: latest, to: Date()).day ?? 0)
    }

    var upcomingReminders: [Reminder] {
        reminders.filter { !$0.isCompleted }.sorted { $0.dueDate < $1.dueDate }
    }

    var overdueReminders: [Reminder] {
        reminders.filter { $0.isOverdue }
    }

    var activityHeatmap: [Date: Int] {
        var map: [Date: Int] = [:]
        for log in logs {
            let day = Calendar.current.startOfDay(for: log.date)
            map[day, default: 0] += 1
        }
        return map
    }

    var categoryBreakdown: [(HomeCategory, Double)] {
        let grouped = Dictionary(grouping: logs, by: \.category)
        return grouped.map { ($0.key, $0.value.compactMap(\.cost).reduce(0, +)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    var categoryLogCounts: [(HomeCategory, Int)] {
        let grouped = Dictionary(grouping: logs, by: \.category)
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    // MARK: - Financial Data

    var yearlySpend: Double {
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return logs.filter { $0.date > oneYearAgo }.compactMap(\.cost).reduce(0, +)
    }

    var projectedAnnualSpend: Double {
        guard !logs.isEmpty else { return 0 }

        guard let earliest = logs.map(\.date).min() else { return 0 }
        let daysCovered = max(1, Calendar.current.dateComponents([.day], from: earliest, to: Date()).day ?? 1)

        // Need at least 14 days of data for projection to be meaningful
        // Otherwise just show actual total
        guard daysCovered >= 14 else { return totalSpend }

        let totalInPeriod = logs.compactMap(\.cost).reduce(0, +)
        return totalInPeriod * (365.0 / Double(daysCovered))
    }

    var avgCostPerEntry: Double {
        let costs = logs.compactMap(\.cost).filter { $0 > 0 }
        guard !costs.isEmpty else { return 0 }
        return costs.reduce(0, +) / Double(costs.count)
    }

    var spendByMonth: [(String, Double)] {
        let cal = Calendar.current
        var result: [(String, Double)] = []
        for i in (0..<6).reversed() {
            guard let monthDate = cal.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let label = monthDate.formatted(.dateTime.month(.abbreviated))
            let spend = logs.filter {
                cal.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }.compactMap(\.cost).reduce(0, +)
            result.append((label, spend))
        }
        return result
    }

    var estimatedSavingsFromPrevention: Double {
        guard !logs.isEmpty else { return 0 }

        // Calculate based on actual data:
        // 1. Routine maintenance costs X → if deferred, emergency repair costs 3-5× more
        // 2. Each on-time task saved you the emergency markup
        let routineLogs = logs.filter { $0.priority == .routine }
        let routineSpend = routineLogs.compactMap(\.cost).reduce(0, +)

        // Emergency repairs you avoided by doing preventive work
        // Industry avg: deferred maintenance costs 3× the preventive cost
        let avoidedEmergencyCost = routineSpend * 2.0 // You'd have paid 3× total, saved 2×

        // Zero-cost routine tasks (testing smoke detectors, cleaning, etc.)
        // still prevent costly failures — avg $150 emergency call avoided per free task
        let freeTasks = routineLogs.filter { ($0.cost ?? 0) == 0 }.count
        let freeTaskSavings = Double(freeTasks) * 150

        return avoidedEmergencyCost + freeTaskSavings
    }

    // MARK: - ML Health Score

    var categoryGrades: [CategoryGrade] {
        HomeCategory.allCases.filter { $0 != .other }.map { cat in
            HomeHealthScorer.gradeCategory(cat, logs: logs, reminders: reminders)
        }
    }

    private func computeScore() -> (Int, [ScoreComponent]) {
        // If no data yet, return neutral score
        guard !logs.isEmpty || !reminders.isEmpty else {
            return (75, [ScoreComponent(label: "Log your first task to get a real score", impact: 0, type: .positive)])
        }

        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()

        let homeAge: Int
        if let yearBuilt = currentHome.yearBuilt {
            homeAge = Calendar.current.component(.year, from: Date()) - yearBuilt
        } else {
            homeAge = 15
        }

        let engine = MaintenanceMLEngine(logs: logs, appliances: appliances, homeAge: homeAge)
        let eolAppliances = engine.applianceAlerts().count

        let features = HomeHealthScorer.Features(
            overdueCount: overdueReminders.count,
            daysSinceLastLog: daysSinceLastService,
            logsThisMonth: monthlyTaskCount,
            logsThisQuarter: logs.filter { $0.date > threeMonthsAgo }.count,
            categoriesCoveredLast6Mo: Set(logs.filter { $0.date > sixMonthsAgo }.map(\.category)).count,
            totalCategories: 6,
            expiredWarranties: appliances.filter { ($0.warrantyExpiry ?? .distantFuture) < Date() }.count,
            appliancesNearEndOfLife: eolAppliances,
            hasContractors: !contractors.isEmpty,
            homeAgeYears: homeAge,
            recurringTasksSetUp: logs.filter { $0.recurringInterval != nil }.count,
            completedRemindersLast30d: reminders.filter { ($0.completedAt ?? .distantPast) > thirtyDaysAgo }.count
        )

        let result = HomeHealthScorer.score(features: features)
        return (result.score, result.breakdown)
    }

    // MARK: - Mutations

    /// Add a log entry. Set `autoSchedule: true` (default) to auto-create the next
    /// maintenance reminder via MaintenanceScheduler. Set `false` when the caller
    /// handles scheduling separately (e.g. the follow-up sheet).
    func addLog(_ entry: LogEntry, autoSchedule: Bool = true) {
        logs.insert(entry, at: 0)

        if autoSchedule {
            scheduleFollowUp(for: entry)
        }

        refreshAchievements()
    }

    /// Creates a future reminder based on the task that was just logged.
    func scheduleFollowUp(for entry: LogEntry) {
        let nextDate: Date
        let recurInterval: RecurringInterval?

        if let interval = entry.recurringInterval {
            nextDate = nextOccurrence(from: entry.date, interval: interval)
            recurInterval = interval
        } else {
            nextDate = MaintenanceScheduler.nextCheckIn(
                for: entry.title, category: entry.category, from: entry.date
            )
            let info = MaintenanceScheduler.recommendedInterval(
                for: entry.title, category: entry.category
            )
            recurInterval = intervalFromDays(info.days)
        }

        // Don't duplicate — check title + category
        let alreadyScheduled = reminders.contains {
            $0.title == entry.title && $0.category == entry.category && !$0.isCompleted && $0.dueDate > Date()
        }
        guard !alreadyScheduled else { return }

        let reminder = Reminder(
            id: UUID(),
            homeId: entry.homeId,
            title: entry.title,
            dueDate: nextDate,
            recurring: recurInterval,
            category: entry.category
        )
        reminders.append(reminder)
    }

    /// Returns the recommended next check-in date for display in UI.
    func suggestedFollowUp(for title: String, category: HomeCategory) -> (date: Date, label: String) {
        let date = MaintenanceScheduler.nextCheckIn(for: title, category: category)
        let info = MaintenanceScheduler.recommendedInterval(for: title, category: category)
        return (date, info.label)
    }

    func intervalFromDays(_ days: Int) -> RecurringInterval? {
        switch days {
        case 0..<45: return .monthly
        case 45..<120: return .quarterly
        case 120..<270: return .semiAnnual
        case 270..<600: return .annual
        default: return nil
        }
    }

    func deleteLog(_ entry: LogEntry) {
        logs.removeAll { $0.id == entry.id }
    }

    func updateLog(_ entry: LogEntry) {
        if let idx = logs.firstIndex(where: { $0.id == entry.id }) {
            logs[idx] = entry
        }
    }

    func completeReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].completedAt = Date()

            // Auto-create next occurrence if recurring
            if let interval = reminder.recurring {
                let nextDate = nextOccurrence(from: Date(), interval: interval)

                // Check for duplicates before adding
                let alreadyExists = reminders.contains {
                    $0.title == reminder.title && !$0.isCompleted && $0.dueDate > Date()
                }
                guard !alreadyExists else { return }

                let next = Reminder(
                    id: UUID(),
                    homeId: reminder.homeId,
                    title: reminder.title,
                    dueDate: nextDate,
                    recurring: interval,
                    category: reminder.category
                )
                reminders.append(next)
            }
        }
    }

    func addContractor(_ contractor: Contractor) {
        contractors.append(contractor)
    }

    func addAppliance(_ appliance: Appliance) {
        appliances.append(appliance)
    }

    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        // Schedule notifications
        NotificationManager.shared.scheduleReminder(reminder)
        NotificationManager.shared.scheduleDayBeforeWarning(reminder)
    }

    /// Restore all data from CloudKit (e.g., new device, reinstall)
    func restoreFromCloud(logs: [LogEntry], contractors: [Contractor], reminders: [Reminder], appliances: [Appliance]) {
        self.logs = logs
        self.contractors = contractors
        self.reminders = reminders
        self.appliances = appliances
        refreshAchievements()
    }

    // MARK: - Custom Quick Logs

    struct QuickLogItem: Codable {
        let title: String
        let category: HomeCategory
        let cost: Double?
    }

    var customQuickLogs: [QuickLogItem] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(customQuickLogs) {
                UserDefaults.standard.set(data, forKey: "hb_quick_logs")
            }
        }
    }

    func addQuickLogShortcut(title: String, category: HomeCategory, cost: Double?) {
        let item = QuickLogItem(title: title, category: category, cost: cost)
        customQuickLogs.append(item)
    }

    func quickLog(title: String, category: HomeCategory, cost: Double?) {
        let entry = LogEntry(
            id: UUID(),
            homeId: currentHome.id,
            category: category,
            title: title,
            date: Date(),
            cost: cost,
            priority: .routine,
            photoURLs: []
        )
        addLog(entry)
    }

    // MARK: - Achievements

    private func refreshAchievements() {
        let userId = user.id
        var updated: [Achievement] = Achievement.AchievementType.allCases.map { type in
            if let existing = achievements.first(where: { $0.type == type }) {
                return existing
            }
            return Achievement(id: UUID(), userId: userId, type: type, unlockedAt: nil)
        }

        // Check unlock conditions
        for i in updated.indices {
            if updated[i].isUnlocked { continue }
            let shouldUnlock: Bool
            switch updated[i].type {
            case .firstLog: shouldUnlock = logs.count >= 1
            case .tenLogs: shouldUnlock = logs.count >= 10
            case .fiftyLogs: shouldUnlock = logs.count >= 50
            case .tracked1K: shouldUnlock = totalSpend >= 1000
            case .tracked10K: shouldUnlock = totalSpend >= 10000
            case .firstContractor: shouldUnlock = contractors.count >= 1
            case .allCategories:
                shouldUnlock = Set(logs.map(\.category)).count >= HomeCategory.allCases.count - 1
            default: shouldUnlock = false
            }
            if shouldUnlock { updated[i].unlockedAt = Date() }
        }
        achievements = updated
    }

    // MARK: - Persistence (UserDefaults JSON)

    private static let logsKey = "hb_logs"
    private static let contractorsKey = "hb_contractors"
    private static let remindersKey = "hb_reminders"
    private static let appliancesKey = "hb_appliances"

    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(logs) {
            UserDefaults.standard.set(data, forKey: Self.logsKey)
        }
        if let data = try? encoder.encode(contractors) {
            UserDefaults.standard.set(data, forKey: Self.contractorsKey)
        }
        if let data = try? encoder.encode(reminders) {
            UserDefaults.standard.set(data, forKey: Self.remindersKey)
        }
        if let data = try? encoder.encode(appliances) {
            UserDefaults.standard.set(data, forKey: Self.appliancesKey)
        }

        // Debounced CloudKit sync (waits 2s after last change)
        CloudKitManager.shared.debouncedSync(appStore: self)
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "hb_quick_logs"),
           let decoded = try? decoder.decode([QuickLogItem].self, from: data) {
            customQuickLogs = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.logsKey),
           let decoded = try? decoder.decode([LogEntry].self, from: data) {
            logs = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.contractorsKey),
           let decoded = try? decoder.decode([Contractor].self, from: data) {
            contractors = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.remindersKey),
           let decoded = try? decoder.decode([Reminder].self, from: data) {
            reminders = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.appliancesKey),
           let decoded = try? decoder.decode([Appliance].self, from: data) {
            appliances = decoded
        }
    }

    // MARK: - Helpers

    private func nextOccurrence(from date: Date, interval: RecurringInterval) -> Date {
        let cal = Calendar.current
        switch interval {
        case .monthly: return cal.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly: return cal.date(byAdding: .month, value: 3, to: date) ?? date
        case .semiAnnual: return cal.date(byAdding: .month, value: 6, to: date) ?? date
        case .annual: return cal.date(byAdding: .year, value: 1, to: date) ?? date
        case .custom: return cal.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

private extension Date {
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
