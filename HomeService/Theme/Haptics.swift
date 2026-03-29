import UIKit

enum HBHaptic {
    /// Light tap — chip/bubble selections, toggles
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — button presses, card taps
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy thud — completing important actions
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Success — log saved, reminder completed
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning — overdue task, approaching deadline
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error — failed action, validation error
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Selection tick — scrolling through options, stepping through onboarding
    static func tick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
