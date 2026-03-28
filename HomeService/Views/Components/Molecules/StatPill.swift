import SwiftUI

struct StatPill: View {
    let title: String
    let value: String
    var icon: String? = nil
    var color: Color = .hbPrimary

    @State private var appeared = false

    var body: some View {
        VStack(spacing: HBSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            Text(value)
                .font(HBTypography.statSmall)
                .foregroundColor(.hbTextPrimary)
                .monospacedDigit()
            Text(title)
                .font(HBTypography.caption)
                .foregroundColor(.hbTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(HBAnimation.springBounce.delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct QuickStatsRow: View {
    let spent: Double
    let tasksLogged: Int
    let daysSinceService: Int

    var body: some View {
        HStack(spacing: HBSpacing.sm) {
            StatPill(
                title: "This Month",
                value: "$\(Int(spent))",
                icon: "dollarsign.circle",
                color: .hbPrimary
            )
            StatPill(
                title: "Tasks Logged",
                value: "\(tasksLogged)",
                icon: "checkmark.circle",
                color: .hbPlumbing
            )
            StatPill(
                title: "Days Since",
                value: "\(daysSinceService)",
                icon: "calendar",
                color: .hbElectrical
            )
        }
    }
}

#Preview {
    QuickStatsRow(spent: 450, tasksLogged: 12, daysSinceService: 3)
        .padding()
}
