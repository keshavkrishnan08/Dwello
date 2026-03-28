import SwiftUI

enum HomeCategory: String, CaseIterable, Identifiable, Codable {
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case hvac = "HVAC"
    case exterior = "Exterior"
    case appliance = "Appliances"
    case structural = "Structure"
    case other = "Other"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .plumbing: return .hbPlumbing
        case .electrical: return .hbElectrical
        case .hvac: return .hbHVAC
        case .exterior: return .hbExterior
        case .appliance: return .hbAppliance
        case .structural: return .hbStructural
        case .other: return .hbTextSecondary
        }
    }

    var icon: String {
        switch self {
        case .plumbing: return "drop.fill"
        case .electrical: return "bolt.fill"
        case .hvac: return "thermometer.medium"
        case .exterior: return "tree.fill"
        case .appliance: return "gearshape.fill"
        case .structural: return "house.fill"
        case .other: return "wrench.fill"
        }
    }
}

enum Priority: String, CaseIterable, Identifiable, Codable {
    case routine = "Routine"
    case important = "Important"
    case urgent = "Urgent"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .routine: return .hbPrimary
        case .important: return .hbWarning
        case .urgent: return .hbDanger
        }
    }
}

enum RecurringInterval: String, CaseIterable, Identifiable, Codable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnual = "Semi-Annual"
    case annual = "Annual"
    case custom = "Custom"

    var id: String { rawValue }
}
