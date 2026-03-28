import SwiftUI

struct HBChip: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false
    var accentColor: Color = .hbPrimary
    let action: () -> Void

    @State private var animateSelection = false

    private var selectedBg: Color {
        accentColor == .hbPrimary ? Color.hbPrimaryLight : accentColor.opacity(0.12)
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(HBAnimation.springInteractive) {
                animateSelection.toggle()
            }
            action()
        }) {
            HStack(spacing: HBSpacing.sm) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? accentColor : .hbTextSecondary)
                }
                Text(title)
                    .font(HBTypography.chip)
                    .foregroundColor(isSelected ? accentColor : .hbTextPrimary)
            }
            .padding(.horizontal, HBSpacing.md)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(isSelected ? selectedBg : Color.hbSurfaceWarm)
            .cornerRadius(HBRadii.chip)
            .overlay(
                RoundedRectangle(cornerRadius: HBRadii.chip)
                    .stroke(isSelected ? accentColor : Color.hbBorder.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct HBChipGrid: View {
    let items: [String]
    @Binding var selectedItems: Set<String>

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items, id: \.self) { item in
                HBChip(
                    title: item,
                    isSelected: selectedItems.contains(item)
                ) {
                    if selectedItems.contains(item) {
                        selectedItems.remove(item)
                    } else {
                        selectedItems.insert(item)
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout for Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

#Preview {
    HBChip(title: "Plumbing", icon: "drop.fill", isSelected: true, action: {})
}
