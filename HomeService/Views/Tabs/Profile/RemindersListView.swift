import SwiftUI

struct RemindersListView: View {
    @Environment(AppStore.self) private var appStore
    @State private var filter: ReminderFilter = .upcoming
    @State private var showingAddSheet = false

    enum ReminderFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case completed = "Completed"
    }

    private var filteredReminders: [Reminder] {
        switch filter {
        case .upcoming:
            return appStore.reminders.filter { !$0.isCompleted && !$0.isOverdue }.sorted { $0.dueDate < $1.dueDate }
        case .overdue:
            return appStore.reminders.filter { $0.isOverdue }.sorted { $0.dueDate < $1.dueDate }
        case .completed:
            return appStore.reminders.filter { $0.isCompleted }.sorted { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) }
        }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Filter tabs
                HStack(spacing: HBSpacing.sm) {
                    ForEach(ReminderFilter.allCases, id: \.self) { reminderFilter in
                        Button(action: {
                            withAnimation(HBAnimation.fast) { filter = reminderFilter }
                        }) {
                            Text(reminderFilter.rawValue)
                                .font(HBTypography.chip)
                                .foregroundColor(filter == reminderFilter ? .white : .hbTextSecondary)
                                .padding(.horizontal, HBSpacing.md)
                                .padding(.vertical, HBSpacing.sm)
                                .background(filter == reminderFilter ? Color.hbPrimary : Color.hbSurface)
                                .cornerRadius(HBRadii.chip)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, HBSpacing.lg)
                .padding(.vertical, HBSpacing.sm)

                if filteredReminders.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No \(filter.rawValue.lowercased()) reminders",
                        subtitle: filter == .completed ? "Completed reminders appear here" : "You're all caught up!"
                    )
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HBSpacing.sm) {
                            ForEach(filteredReminders) { reminder in
                                ReminderRow(
                                    reminder: reminder,
                                    onComplete: {
                                        withAnimation(HBAnimation.springInteractive) {
                                            appStore.completeReminder(reminder)
                                        }
                                    },
                                    onSnooze: {
                                        // Snooze action
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.hbPrimary)
                }
                .accessibilityLabel("Add reminder")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddReminderSheet()
                .environment(appStore)
        }
    }
}

// MARK: - Add Reminder Sheet
struct AddReminderSheet: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var dueDate = Date()
    @State private var category: HomeCategory = .hvac
    @State private var isRecurring = false
    @State private var interval: RecurringInterval = .monthly

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        HBTextField(title: "Title", text: $title, placeholder: "e.g., Change HVAC filter", icon: "bell.fill")

                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Due Date")
                                .font(HBTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(.hbTextSecondary)
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.hbPrimary)
                        }

                        CategoryChipSelector(selected: $category)

                        Toggle(isOn: $isRecurring) {
                            HStack(spacing: HBSpacing.sm) {
                                Image(systemName: "repeat")
                                    .foregroundColor(.hbTextSecondary)
                                Text("Recurring")
                                    .font(HBTypography.body)
                                    .foregroundColor(.hbTextPrimary)
                            }
                        }
                        .tint(.hbPrimary)

                        if isRecurring {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: HBSpacing.sm) {
                                    ForEach(RecurringInterval.allCases) { i in
                                        HBChip(title: i.rawValue, isSelected: interval == i) {
                                            interval = i
                                        }
                                    }
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        HBButton(title: "Save Reminder", isEnabled: isValid) {
                            let reminder = Reminder(
                                id: UUID(),
                                homeId: appStore.currentHome.id,
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                dueDate: dueDate,
                                recurring: isRecurring ? interval : nil,
                                category: category
                            )
                            appStore.addReminder(reminder)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.hbTextSecondary)
                }
            }
        }
    }
}
