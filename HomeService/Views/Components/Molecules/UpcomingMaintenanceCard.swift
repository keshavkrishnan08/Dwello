import SwiftUI

struct UpcomingMaintenanceCard: View {
    let reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HStack(spacing: HBSpacing.sm) {
                Circle()
                    .fill(reminder.category.color)
                    .frame(width: 8, height: 8)
                Image(systemName: reminder.category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(reminder.category.color)
            }

            Text(reminder.title)
                .font(HBTypography.body)
                .fontWeight(.medium)
                .foregroundColor(.hbTextPrimary)
                .lineLimit(2)

            HStack {
                Text(reminder.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(HBTypography.caption)
                    .foregroundColor(reminder.isOverdue ? .hbDanger : .hbTextSecondary)

                if reminder.isOverdue {
                    Text("Overdue")
                        .font(HBTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.hbDanger)
                }
            }
        }
        .padding(HBSpacing.md)
        .frame(width: 160, alignment: .leading)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }
}

struct UpcomingMaintenanceRow: View {
    let reminders: [Reminder]

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HStack {
                Text("Upcoming Maintenance")
                    .font(HBTypography.h2)
                    .foregroundColor(.hbTextPrimary)
                Spacer()
                Button("See All") {}
                    .font(HBTypography.bodySmall)
                    .foregroundColor(.hbPrimary)
            }
            .padding(.horizontal, HBSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HBSpacing.sm) {
                    ForEach(reminders) { reminder in
                        UpcomingMaintenanceCard(reminder: reminder)
                    }
                }
                .padding(.horizontal, HBSpacing.lg)
            }
        }
    }
}

// MARK: - Seasonal Tips Banner
struct SeasonalTipsBanner: View {
    @State private var appeared = false

    var currentSeason: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "Spring"
        case 6...8: return "Summer"
        case 9...11: return "Fall"
        default: return "Winter"
        }
    }

    var seasonIcon: String {
        switch currentSeason {
        case "Spring": return "leaf.fill"
        case "Summer": return "sun.max.fill"
        case "Fall": return "wind"
        default: return "snowflake"
        }
    }

    var seasonTip: String {
        switch currentSeason {
        case "Spring": return "Time to inspect your roof and clean out gutters after winter"
        case "Summer": return "Check your AC filters and inspect outdoor areas"
        case "Fall": return "Prepare your home for winter — check insulation and heating"
        default: return "Protect pipes from freezing and check your heating system"
        }
    }

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.hbPrimaryLight)
                    .frame(width: 48, height: 48)
                Image(systemName: seasonIcon)
                    .font(.system(size: 22))
                    .foregroundColor(.hbPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentSeason) Maintenance")
                    .font(HBTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.hbTextPrimary)
                Text(seasonTip)
                    .font(HBTypography.bodySmall)
                    .foregroundColor(.hbTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.hbBorder)
        }
        .padding(HBSpacing.md)
        .background(
            LinearGradient(
                colors: [Color.hbPrimaryLight.opacity(0.5), Color.hbSurface],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(HBAnimation.springGentle.delay(0.5)) {
                appeared = true
            }
        }
    }
}

#Preview {
    VStack {
        UpcomingMaintenanceCard(reminder: Reminder.samples[0])
        SeasonalTipsBanner()
            .padding()
    }
}
