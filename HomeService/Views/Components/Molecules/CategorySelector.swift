import SwiftUI

struct CategoryChipBar: View {
    @Binding var selected: HomeCategory?
    var showAll: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if showAll {
                    HBChip(title: "All", isSelected: selected == nil) {
                        withAnimation(HBAnimation.fast) { selected = nil }
                    }
                }
                ForEach(HomeCategory.allCases.filter { $0 != .other }) { category in
                    HBChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selected == category,
                        accentColor: category.color
                    ) {
                        withAnimation(HBAnimation.fast) { selected = category }
                    }
                }
            }
            .padding(.horizontal, HBSpacing.lg)
        }
    }
}

// MARK: - Circular Category Selector (Life Areas / Onboarding Screen 5)
struct CircularCategorySelector: View {
    @Binding var selectedCategories: Set<HomeCategory>

    let categories: [HomeCategory] = [.plumbing, .electrical, .hvac, .exterior, .appliance, .structural]
    let radius: CGFloat = 120

    @State private var appeared = false

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("\(selectedCategories.count)")
                    .font(HBTypography.statNumber)
                    .foregroundColor(.hbTextPrimary)
                    .contentTransition(.numericText())
                Text("areas")
                    .font(HBTypography.bodySmall)
                    .foregroundColor(.hbTextSecondary)
            }

            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                let angle = Angle(degrees: Double(index) * 60 - 90)
                let isSelected = selectedCategories.contains(category)
                let color: Color = index % 2 == 0 ? .hbPrimary : .hbLavender

                CircularCategoryItem(
                    category: category,
                    isSelected: isSelected,
                    color: color
                ) {
                    withAnimation(HBAnimation.springInteractive) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
                .offset(
                    x: appeared ? cos(angle.radians) * radius : 0,
                    y: appeared ? sin(angle.radians) * radius : 0
                )
                .scaleEffect(appeared ? 1 : 0)
                .animation(
                    HBAnimation.springBounce.delay(Double(index) * 0.08),
                    value: appeared
                )
            }
        }
        .frame(width: radius * 2 + 80, height: radius * 2 + 100)
        .onAppear { appeared = true }
    }
}

struct CircularCategoryItem: View {
    let category: HomeCategory
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.12) : Color.white)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle().stroke(color, lineWidth: isSelected ? 2.5 : 1.5)
                        )
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(HBAnimation.springInteractive, value: isSelected)

                Text(category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? color : .hbTextSecondary)
                    .lineLimit(1)
                    .frame(width: 64)
            }
        }
        .accessibilityLabel(category.rawValue)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Category Chip Selector for Log Entry
struct CategoryChipSelector: View {
    @Binding var selected: HomeCategory

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            Text("Category")
                .font(HBTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.hbTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HomeCategory.allCases) { category in
                        HBChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selected == category,
                            accentColor: category.color
                        ) {
                            withAnimation(HBAnimation.fast) {
                                selected = category
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CircularCategorySelector(selectedCategories: .constant([.plumbing, .hvac]))
}
