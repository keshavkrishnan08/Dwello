import SwiftUI

struct SelectionCard: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: HBSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .hbPrimary : .hbTextSecondary)
                        .frame(width: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HBTypography.body)
                        .foregroundColor(.hbTextPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(HBTypography.bodySmall)
                            .foregroundColor(.hbTextSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.hbPrimary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(HBSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isSelected ? Color.hbPrimaryLight.opacity(0.5) : Color.hbSurfaceWarm)
            .cornerRadius(HBRadii.input)
            .overlay(
                RoundedRectangle(cornerRadius: HBRadii.input)
                    .stroke(isSelected ? Color.hbPrimary : Color.hbBorder.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct SelectionCardGroup<T: Identifiable & Hashable>: View {
    let items: [T]
    @Binding var selection: T?
    let titleForItem: (T) -> String
    var iconForItem: ((T) -> String)? = nil
    var subtitleForItem: ((T) -> String?)? = nil

    var body: some View {
        VStack(spacing: HBSpacing.sm + 4) {
            ForEach(items) { item in
                SelectionCard(
                    title: titleForItem(item),
                    subtitle: subtitleForItem?(item),
                    icon: iconForItem?(item),
                    isSelected: selection == item
                ) {
                    withAnimation(HBAnimation.springInteractive) {
                        selection = item
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        SelectionCard(title: "Single-family house", icon: "house.fill", isSelected: true, action: {})
        SelectionCard(title: "Townhouse", icon: "building.2.fill", isSelected: false, action: {})
    }
    .padding()
}
