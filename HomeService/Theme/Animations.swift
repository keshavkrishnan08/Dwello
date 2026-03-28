import SwiftUI

struct HBAnimation {
    /// Whether the user has enabled Reduce Motion in accessibility settings.
    /// All non-essential animations should be suppressed when true.
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - Spring Configs
    static var springInteractive: Animation {
        prefersReducedMotion ? .easeOut(duration: 0.1) : .spring(response: 0.35, dampingFraction: 0.7)
    }
    static var springBounce: Animation {
        prefersReducedMotion ? .easeOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.6)
    }
    static var springGentle: Animation {
        prefersReducedMotion ? .easeOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.8)
    }

    // MARK: - Timing Configs
    static var transition: Animation {
        prefersReducedMotion ? .easeOut(duration: 0.1) : .easeInOut(duration: 0.3)
    }
    static var fast: Animation {
        .easeOut(duration: prefersReducedMotion ? 0.05 : 0.15)
    }
    static var medium: Animation {
        .easeInOut(duration: prefersReducedMotion ? 0.1 : 0.3)
    }
    static var slow: Animation {
        .easeInOut(duration: prefersReducedMotion ? 0.15 : 0.6)
    }

    // MARK: - Stagger
    static var staggerDelay: Double {
        prefersReducedMotion ? 0.02 : 0.08
    }

    // MARK: - Decorative (disabled entirely with Reduce Motion)
    static var pulse: Animation? {
        prefersReducedMotion ? nil : .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }
    static var shimmer: Animation? {
        prefersReducedMotion ? nil : .linear(duration: 3.0).repeatForever(autoreverses: false)
    }

    // MARK: - Digit Roll
    static var digitRoll: Animation {
        .easeOut(duration: prefersReducedMotion ? 0.1 : 0.6)
    }
}

// MARK: - Transition Helpers
extension AnyTransition {
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    static var fadeScale: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }

    static func staggered(index: Int) -> AnyTransition {
        .asymmetric(
            insertion: .offset(y: 20).combined(with: .opacity),
            removal: .opacity
        )
    }
}
