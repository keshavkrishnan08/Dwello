import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Schedule Reminder Notification

    func scheduleReminder(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminderTitle(for: reminder)
        content.body = reminderBody(for: reminder)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MAINTENANCE_REMINDER"

        // Trigger at 9 AM on the due date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reminder.dueDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Schedule Day-Before Warning

    func scheduleDayBeforeWarning(_ reminder: Reminder) {
        guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: reminder.dueDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Tomorrow: \(reminder.title)"
        content.body = "Heads up — \(reminder.title.lowercased()) is due tomorrow. Got everything you need?"
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE_REMINDER"

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(reminder.id.uuidString)-warning",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Weekly Summary

    func scheduleWeeklySummary(overdueCount: Int, upcomingCount: Int, healthScore: Int) {
        let content = UNMutableNotificationContent()
        content.title = weeklyTitle(healthScore: healthScore)
        content.body = weeklySummary(overdue: overdueCount, upcoming: upcomingCount, score: healthScore)
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        // Every Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Seasonal Nudge

    func scheduleSeasonalNudge() {
        let month = Calendar.current.component(.month, from: Date())
        let (title, body) = seasonalMessage(month: month)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // First of next month at 9 AM
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date()) else { return }
        var dateComponents = Calendar.current.dateComponents([.year, .month], from: nextMonth)
        dateComponents.day = 1
        dateComponents.hour = 9

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "seasonal-\(month)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel

    func cancelReminder(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id.uuidString, "\(id.uuidString)-warning"]
        )
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Register Categories

    func registerCategories() {
        let completeAction = UNNotificationAction(identifier: "MARK_DONE", title: "Mark Done", options: [])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Remind Tomorrow", options: [])

        let reminderCategory = UNNotificationCategory(
            identifier: "MAINTENANCE_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: []
        )

        let summaryCategory = UNNotificationCategory(
            identifier: "WEEKLY_SUMMARY",
            actions: [],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([reminderCategory, summaryCategory])
    }

    // MARK: - Creative Copy

    private func reminderTitle(for reminder: Reminder) -> String {
        let titles: [HomeCategory: [String]] = [
            .hvac: ["🌡️ HVAC Check-in", "❄️ Climate Control Time", "🔥 Heating & Cooling"],
            .plumbing: ["🔧 Plumbing Reminder", "💧 Water Works", "🚿 Pipes & Fixtures"],
            .electrical: ["⚡ Electrical Check", "💡 Safety First", "🔌 Power Up"],
            .exterior: ["🌿 Outdoor Maintenance", "🏡 Curb Appeal", "🍂 Exterior Check"],
            .appliance: ["⚙️ Appliance Care", "🧹 Machine Maintenance", "🔩 Appliance Check"],
            .structural: ["🏗️ Structure Check", "🧱 Foundation & Frame", "🔨 Structural Health"],
            .other: ["🏠 Home Task", "📋 Maintenance Due", "✅ Check-in Time"],
        ]
        let options = titles[reminder.category] ?? ["🏠 Maintenance Due"]
        return options.randomElement() ?? options[0]
    }

    private func reminderBody(for reminder: Reminder) -> String {
        let bodies = [
            "Time for: \(reminder.title). Your home will thank you!",
            "\(reminder.title) is due today. Quick task, big impact.",
            "Don't forget — \(reminder.title). Staying on schedule keeps costs down.",
            "\(reminder.title) is on your list today. Knock it out! 💪",
            "Reminder: \(reminder.title). Preventive care saves money long-term.",
        ]
        return bodies.randomElement() ?? bodies[0]
    }

    private func weeklyTitle(healthScore: Int) -> String {
        if healthScore >= 90 { return "🏆 Home Health: Excellent!" }
        if healthScore >= 75 { return "👍 Weekly Home Check-in" }
        if healthScore >= 60 { return "⚠️ Your Home Needs You" }
        return "🚨 Home Health Alert"
    }

    private func weeklySummary(overdue: Int, upcoming: Int, score: Int) -> String {
        if overdue == 0 && upcoming == 0 {
            return "Score: \(score)/100. All caught up — great job staying on top of things!"
        }
        if overdue > 0 {
            return "Score: \(score)/100. You have \(overdue) overdue task\(overdue == 1 ? "" : "s") and \(upcoming) upcoming. Open Dwillo to catch up."
        }
        return "Score: \(score)/100. \(upcoming) task\(upcoming == 1 ? "" : "s") coming up this week. Stay ahead!"
    }

    private func seasonalMessage(month: Int) -> (String, String) {
        switch month {
        case 3...5: return ("🌱 Spring Maintenance Season", "Time to inspect the roof, clean gutters, and service the AC before summer hits.")
        case 6...8: return ("☀️ Summer Home Care", "Check your irrigation, clean dryer vents, and replace AC filters monthly.")
        case 9...11: return ("🍂 Fall Prep Checklist", "Service the furnace, drain outdoor faucets, and seal gaps before winter.")
        default: return ("❄️ Winter Home Watch", "Monitor pipes for freezing, check the water heater, and test smoke detectors.")
        }
    }
}
