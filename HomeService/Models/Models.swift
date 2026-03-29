import Foundation
import SwiftUI

// MARK: - User
struct HBUser: Identifiable, Codable {
    let id: UUID
    var email: String
    var name: String
    var createdAt: Date
    var subscriptionTier: SubscriptionTier

    enum SubscriptionTier: String, Codable {
        case free, premium
    }

    static let sample = HBUser(
        id: UUID(),
        email: "demo@dwillo.com",
        name: "Alex",
        createdAt: Date(),
        subscriptionTier: .free
    )
}

// MARK: - Home
struct Home: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var name: String
    var type: HomeType
    var yearBuilt: Int? = nil
    var sqft: Int? = nil
    var address: String? = nil
    var photoURL: String? = nil

    enum HomeType: String, CaseIterable, Codable, Identifiable {
        case singleFamily = "Single-Family House"
        case townhouse = "Townhouse / Row Home"
        case condo = "Condo / Apartment"
        case multiFamily = "Multi-Family / Duplex"
        case mobile = "Mobile / Manufactured"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .singleFamily: return "house.fill"
            case .townhouse: return "building.2.fill"
            case .condo: return "building.fill"
            case .multiFamily: return "house.and.flag.fill"
            case .mobile: return "house.circle.fill"
            }
        }
    }

    static let sample = Home(
        id: UUID(),
        userId: UUID(),
        name: "My Home",
        type: .singleFamily,
        yearBuilt: 2005,
        sqft: 2200,
        address: "123 Main St"
    )
}

// MARK: - Log Entry
struct LogEntry: Identifiable, Codable {
    let id: UUID
    var homeId: UUID
    var category: HomeCategory
    var title: String
    var date: Date
    var cost: Double? = nil
    var priority: Priority
    var recurringInterval: RecurringInterval? = nil
    var notes: String? = nil
    var contractorId: UUID? = nil
    var warrantyExpiry: Date? = nil
    var photoURLs: [String] = []

    static let sample = LogEntry(
        id: UUID(),
        homeId: UUID(),
        category: .hvac,
        title: "Changed HVAC filter",
        date: Date(),
        cost: 25.00,
        priority: .routine,
        notes: "Used MERV 13 filter",
        photoURLs: []
    )

    static let samples: [LogEntry] = [
        LogEntry(id: UUID(), homeId: UUID(), category: .hvac, title: "Changed HVAC filter", date: Date(), cost: 25.00, priority: .routine, photoURLs: []),
        LogEntry(id: UUID(), homeId: UUID(), category: .plumbing, title: "Fixed kitchen faucet leak", date: Date().addingTimeInterval(-86400 * 3), cost: 150.00, priority: .important, contractorId: UUID(), photoURLs: []),
        LogEntry(id: UUID(), homeId: UUID(), category: .exterior, title: "Cleaned gutters", date: Date().addingTimeInterval(-86400 * 7), cost: 200.00, priority: .routine, photoURLs: []),
        LogEntry(id: UUID(), homeId: UUID(), category: .electrical, title: "Replaced outlet in bathroom", date: Date().addingTimeInterval(-86400 * 14), cost: 85.00, priority: .important, photoURLs: []),
        LogEntry(id: UUID(), homeId: UUID(), category: .appliance, title: "Dishwasher maintenance", date: Date().addingTimeInterval(-86400 * 21), cost: 0, priority: .routine, photoURLs: []),
        LogEntry(id: UUID(), homeId: UUID(), category: .structural, title: "Patched drywall crack", date: Date().addingTimeInterval(-86400 * 30), cost: 45.00, priority: .routine, photoURLs: []),
    ]
}

// MARK: - Contractor
struct Contractor: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var name: String
    var phone: String? = nil
    var email: String? = nil
    var specialty: HomeCategory? = nil
    var rating: Int // 1-5

    static let sample = Contractor(
        id: UUID(),
        userId: UUID(),
        name: "Mike's Plumbing",
        phone: "555-0123",
        email: "mike@plumbing.com",
        specialty: .plumbing,
        rating: 5
    )

    static let samples: [Contractor] = [
        Contractor(id: UUID(), userId: UUID(), name: "Mike's Plumbing", phone: "555-0123", specialty: .plumbing, rating: 5),
        Contractor(id: UUID(), userId: UUID(), name: "Spark Electric Co", phone: "555-0456", specialty: .electrical, rating: 4),
        Contractor(id: UUID(), userId: UUID(), name: "CoolAir HVAC", phone: "555-0789", specialty: .hvac, rating: 4),
    ]
}

// MARK: - Appliance
struct Appliance: Identifiable, Codable {
    let id: UUID
    var homeId: UUID
    var name: String
    var make: String? = nil
    var model: String? = nil
    var purchaseDate: Date? = nil
    var warrantyExpiry: Date? = nil
    var manualURL: String? = nil

    static let sample = Appliance(
        id: UUID(),
        homeId: UUID(),
        name: "Dishwasher",
        make: "Bosch",
        model: "SHP88PZ55N",
        purchaseDate: Date().addingTimeInterval(-86400 * 365 * 2),
        warrantyExpiry: Date().addingTimeInterval(86400 * 365)
    )
}

// MARK: - Reminder
struct Reminder: Identifiable, Codable {
    let id: UUID
    var homeId: UUID
    var title: String
    var dueDate: Date
    var recurring: RecurringInterval? = nil
    var category: HomeCategory
    var completedAt: Date? = nil

    var isOverdue: Bool { dueDate < Date() && completedAt == nil }
    var isCompleted: Bool { completedAt != nil }

    static let samples: [Reminder] = [
        Reminder(id: UUID(), homeId: UUID(), title: "Change HVAC filter", dueDate: Date().addingTimeInterval(86400 * 2), recurring: .monthly, category: .hvac),
        Reminder(id: UUID(), homeId: UUID(), title: "Clean gutters", dueDate: Date().addingTimeInterval(86400 * 14), recurring: .semiAnnual, category: .exterior),
        Reminder(id: UUID(), homeId: UUID(), title: "Test smoke detectors", dueDate: Date().addingTimeInterval(-86400 * 3), recurring: .semiAnnual, category: .electrical),
        Reminder(id: UUID(), homeId: UUID(), title: "Inspect roof", dueDate: Date().addingTimeInterval(86400 * 30), recurring: .annual, category: .structural),
    ]
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var type: AchievementType
    var unlockedAt: Date? = nil

    var isUnlocked: Bool { unlockedAt != nil }

    enum AchievementType: String, CaseIterable, Codable, Identifiable {
        case firstLog = "First Log"
        case tenLogs = "10 Logs"
        case fiftyLogs = "50 Logs"
        case streak7 = "7-Day Streak"
        case streak30 = "30-Day Streak"
        case tracked1K = "$1K Tracked"
        case tracked10K = "$10K Tracked"
        case allCategories = "All Categories"
        case firstContractor = "First Contractor"
        case photoLogger = "Photo Logger"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .firstLog: return "star.fill"
            case .tenLogs: return "flame.fill"
            case .fiftyLogs: return "trophy.fill"
            case .streak7: return "calendar.badge.checkmark"
            case .streak30: return "calendar.badge.clock"
            case .tracked1K: return "dollarsign.circle.fill"
            case .tracked10K: return "banknote.fill"
            case .allCategories: return "square.grid.3x3.fill"
            case .firstContractor: return "person.badge.plus"
            case .photoLogger: return "camera.fill"
            }
        }

        var description: String {
            switch self {
            case .firstLog: return "Log your first maintenance entry"
            case .tenLogs: return "Log 10 maintenance entries"
            case .fiftyLogs: return "Log 50 maintenance entries"
            case .streak7: return "Log something 7 days in a row"
            case .streak30: return "Log something 30 days in a row"
            case .tracked1K: return "Track $1,000 in home maintenance"
            case .tracked10K: return "Track $10,000 in home maintenance"
            case .allCategories: return "Log in every category"
            case .firstContractor: return "Save your first contractor"
            case .photoLogger: return "Add photos to 10 logs"
            }
        }
    }
}

// MARK: - Onboarding Responses
struct OnboardingResponses: Codable {
    var homeType: Home.HomeType?
    var homeAge: HomeAge?
    var frequency: MaintenanceFrequency?
    var selectedSystems: Set<HomeCategory> = []
    var goals: Set<String> = []
    var biggestChallenge: String?
    var existingSystems: Set<String> = []
    var notificationPreference: NotificationPreference?

    enum HomeAge: String, CaseIterable, Codable, Identifiable {
        case newBuild = "New Build (0–5 years)"
        case established = "Established (5–20 years)"
        case mature = "Mature (20–50 years)"
        case historic = "Historic (50+ years)"

        var id: String { rawValue }

        var shortLabel: String {
            switch self {
            case .newBuild: return "0–5 yrs"
            case .established: return "5–20 yrs"
            case .mature: return "20–50 yrs"
            case .historic: return "50+ yrs"
            }
        }
    }

    enum MaintenanceFrequency: String, CaseIterable, Codable, Identifiable {
        case regularly = "Regularly (monthly+)"
        case sometimes = "Sometimes (quarterly)"
        case rarely = "Rarely (yearly)"
        case whenBreaks = "When things break"
        case justMoved = "Just moved in"

        var id: String { rawValue }
    }

    enum NotificationPreference: String, CaseIterable, Codable, Identifiable {
        case morning = "Morning (8–10am)"
        case afternoon = "Afternoon (12–2pm)"
        case evening = "Evening (6–8pm)"
        case weekends = "Weekends only"
        case later = "I'll decide later"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .weekends: return "calendar"
            case .later: return "clock.fill"
            }
        }
    }
}
