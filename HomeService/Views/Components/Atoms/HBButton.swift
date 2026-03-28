import SwiftUI

struct HBButton: View {
    let title: String
    var style: Style = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    enum Style {
        case primary, secondary, text
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tracking(0.3)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(backgroundColor)
                .cornerRadius(HBRadii.button)
                .overlay(
                    RoundedRectangle(cornerRadius: HBRadii.button)
                        .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
                )
                .hbShadow(style == .primary ? .cta : .sm)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "" : "Currently disabled")
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .hbPrimary
        case .secondary: return .hbSurface
        case .text: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .hbPrimary
        case .text: return .hbPrimary
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return .hbPrimary
        default: return .clear
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct HBTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HBTypography.body)
                .foregroundColor(.hbPrimary)
                .frame(minHeight: 44)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 16) {
        HBButton(title: "Continue", action: {})
        HBButton(title: "Secondary", style: .secondary, action: {})
        HBButton(title: "Disabled", isEnabled: false, action: {})
        HBTextButton(title: "Continue with Free", action: {})
    }
    .padding()
}
