import SwiftUI

struct LogEntryForm: View {
    @Binding var category: HomeCategory
    @Binding var title: String
    @Binding var date: Date
    @Binding var cost: String
    @Binding var notes: String
    @Binding var priority: Priority
    @Binding var isRecurring: Bool
    @Binding var recurringInterval: RecurringInterval?
    @Binding var contractorName: String
    @Binding var contractorRating: Int

    let commonTasks = [
        "Changed HVAC filter", "Cleaned gutters", "Serviced water heater",
        "Replaced smoke detector battery", "Lawn treatment", "Pressure washed deck"
    ]

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            // Category
            CategoryChipSelector(selected: $category)

            // Title with suggestions
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                HBTextField(title: "Title", text: $title, placeholder: "What did you do?", icon: "wrench.fill")

                if title.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: HBSpacing.sm) {
                            ForEach(commonTasks, id: \.self) { task in
                                Button(action: { title = task }) {
                                    Text(task)
                                        .font(HBTypography.caption)
                                        .foregroundColor(.hbPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.hbPrimaryLight)
                                        .cornerRadius(HBRadii.chip)
                                }
                            }
                        }
                    }
                }
            }

            // Date
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                Text("Date")
                    .font(HBTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextSecondary)

                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.hbPrimary)
            }

            // Cost
            HBCurrencyField(title: "Cost (optional)", value: $cost)

            // Priority
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                Text("Priority")
                    .font(HBTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextSecondary)

                HStack(spacing: HBSpacing.sm) {
                    ForEach(Priority.allCases) { p in
                        Button(action: {
                            withAnimation(HBAnimation.fast) { priority = p }
                        }) {
                            Text(p.rawValue)
                                .font(HBTypography.chip)
                                .foregroundColor(priority == p ? .white : p.color)
                                .padding(.horizontal, HBSpacing.md)
                                .padding(.vertical, 10)
                                .background(priority == p ? p.color : p.color.opacity(0.1))
                                .cornerRadius(HBRadii.chip)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            // Recurring
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                Toggle(isOn: $isRecurring) {
                    HStack(spacing: HBSpacing.sm) {
                        Image(systemName: "repeat")
                            .foregroundColor(.hbTextSecondary)
                        Text("Recurring task")
                            .font(HBTypography.body)
                            .foregroundColor(.hbTextPrimary)
                    }
                }
                .tint(.hbPrimary)

                if isRecurring {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: HBSpacing.sm) {
                            ForEach(RecurringInterval.allCases) { interval in
                                HBChip(
                                    title: interval.rawValue,
                                    isSelected: recurringInterval == interval
                                ) {
                                    recurringInterval = interval
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            // Contractor
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                HBTextField(title: "Contractor (optional)", text: $contractorName, placeholder: "Name", icon: "person.fill")

                if !contractorName.isEmpty {
                    HStack(spacing: 4) {
                        Text("Rating:")
                            .font(HBTypography.bodySmall)
                            .foregroundColor(.hbTextSecondary)
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { contractorRating = star }) {
                                Image(systemName: star <= contractorRating ? "star.fill" : "star")
                                    .foregroundColor(.hbElectrical)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }

            // Notes
            HBTextField(title: "Notes (optional)", text: $notes, placeholder: "Additional details...", icon: "note.text", isMultiline: true)

            // Photos placeholder
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                Text("Photos (optional)")
                    .font(HBTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextSecondary)

                HStack(spacing: HBSpacing.sm) {
                    PhotoAddButton(icon: "camera.fill", label: "Camera")
                    PhotoAddButton(icon: "photo.fill", label: "Gallery")
                }
            }
        }
    }
}

struct PhotoAddButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: HBSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.hbTextSecondary)
            Text(label)
                .font(HBTypography.caption)
                .foregroundColor(.hbTextSecondary)
        }
        .frame(width: 80, height: 80)
        .background(Color.hbBackground)
        .cornerRadius(HBRadii.input)
        .overlay(
            RoundedRectangle(cornerRadius: HBRadii.input)
                .stroke(Color.hbBorder, style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
        )
    }
}
