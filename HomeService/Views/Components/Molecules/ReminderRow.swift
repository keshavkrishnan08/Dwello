import SwiftUI

struct ReminderRow: View {
    let reminder: Reminder
    var onComplete: (() -> Void)? = nil
    var onSnooze: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(reminder.category.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: reminder.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(reminder.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(HBTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextPrimary)
                    .strikethrough(reminder.isCompleted)

                HStack(spacing: HBSpacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(reminder.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(HBTypography.caption)

                    if reminder.isOverdue {
                        Text("• OVERDUE")
                            .font(HBTypography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.hbDanger)
                    }

                    if let interval = reminder.recurring {
                        Text("• \(interval.rawValue)")
                            .font(HBTypography.caption)
                    }
                }
                .foregroundColor(reminder.isOverdue ? .hbDanger : .hbTextSecondary)
            }

            Spacer()

            if !reminder.isCompleted {
                HStack(spacing: HBSpacing.sm) {
                    Button(action: { onSnooze?() }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.hbTextSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Snooze reminder")
                    Button(action: { onComplete?() }) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.hbPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Complete reminder")
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.hbPrimary)
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }
}

#Preview {
    VStack {
        ReminderRow(reminder: Reminder.samples[0])
        ReminderRow(reminder: Reminder.samples[2])
    }
    .padding()
}
