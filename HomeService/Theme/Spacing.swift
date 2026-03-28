import SwiftUI

struct HBSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct HBRadii {
    static let card: CGFloat = 16
    static let button: CGFloat = 28
    static let chip: CGFloat = 24
    static let input: CGFloat = 12
    static let modal: CGFloat = 20
    // Small radii for chart elements, badges, inline tags
    static let badge: CGFloat = 8
    static let chartBar: CGFloat = 4
}

struct HBShadow: ViewModifier {
    enum Style {
        case sm, md, lg, cta, hero
    }

    let style: Style

    func body(content: Content) -> some View {
        switch style {
        case .sm:
            content.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        case .md:
            content.shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
        case .lg:
            content.shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -5)
        case .cta:
            content.shadow(color: .hbPrimary.opacity(0.3), radius: 14, x: 0, y: 4)
        case .hero:
            content.shadow(color: .hbPrimary.opacity(0.4), radius: 20, x: 0, y: 4)
        }
    }
}

extension View {
    func hbShadow(_ style: HBShadow.Style) -> some View {
        modifier(HBShadow(style: style))
    }
}
