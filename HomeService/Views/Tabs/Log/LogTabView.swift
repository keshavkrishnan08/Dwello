import SwiftUI

struct LogTabView: View {
    @Environment(AppStore.self) private var appStore

    @State private var category: HomeCategory = .hvac
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var cost: String = ""
    @State private var notes: String = ""
    @State private var priority: Priority = .routine
    @State private var isRecurring: Bool = false
    @State private var recurringInterval: RecurringInterval? = nil
    @State private var contractorName: String = ""
    @State private var contractorRating: Int = 0
    @State private var showingSaveAnimation = false
    @State private var showFollowUpSheet = false
    @State private var savedEntryTitle = ""
    @State private var savedEntryCategory: HomeCategory = .hvac
    @State private var saveTask: Task<Void, Never>?

    private var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var parsedCost: Double? {
        guard !cost.isEmpty else { return nil }
        let cleaned = cost.replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value >= 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.md) {
                        // Section header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What did you work on?")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.hbTextPrimary)
                            Text("Log repairs, maintenance, and improvements")
                                .font(.system(size: 14))
                                .foregroundColor(.hbTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, HBSpacing.lg)
                        .padding(.top, HBSpacing.sm)

                        // Form sections in clean cards
                        VStack(spacing: HBSpacing.sm) {
                            // Category + Title card
                            VStack(spacing: HBSpacing.md) {
                                CategoryChipSelector(selected: $category)

                                HBTextField(title: "Title", text: $title, placeholder: "e.g., Changed HVAC filter", icon: "wrench.fill")

                                if title.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(suggestionsFor(category), id: \.self) { task in
                                                Button(action: { title = task }) {
                                                    Text(task)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.hbPrimary)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(Color.hbPrimary.opacity(0.06))
                                                        .cornerRadius(HBRadii.chip)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(HBSpacing.md)
                            .background(Color.hbSurface)
                            .cornerRadius(HBRadii.card)

                            // Details card
                            VStack(spacing: HBSpacing.md) {
                                HStack(spacing: HBSpacing.md) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Date")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.hbTextSecondary)
                                        DatePicker("", selection: $date, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .tint(.hbPrimary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    HBCurrencyField(title: "Cost", value: $cost)
                                }

                                // Priority inline
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Priority")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.hbTextSecondary)
                                    HStack(spacing: HBSpacing.sm) {
                                        ForEach(Priority.allCases) { p in
                                            Button(action: {
                                                withAnimation(HBAnimation.fast) { priority = p }
                                            }) {
                                                Text(p.rawValue)
                                                    .font(.system(size: 14, weight: priority == p ? .semibold : .medium))
                                                    .foregroundColor(priority == p ? .white : p.color)
                                                    .padding(.horizontal, HBSpacing.md)
                                                    .padding(.vertical, 8)
                                                    .background(priority == p ? p.color : p.color.opacity(0.08))
                                                    .cornerRadius(HBRadii.chip)
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding(HBSpacing.md)
                            .background(Color.hbSurface)
                            .cornerRadius(HBRadii.card)

                            // Recurring + Contractor card
                            VStack(spacing: HBSpacing.md) {
                                Toggle(isOn: $isRecurring) {
                                    HStack(spacing: HBSpacing.sm) {
                                        Image(systemName: "repeat")
                                            .foregroundColor(.hbPrimary.opacity(0.6))
                                        Text("Recurring task")
                                            .font(.system(size: 15))
                                            .foregroundColor(.hbTextPrimary)
                                    }
                                }
                                .tint(.hbPrimary)

                                if isRecurring {
                                    HStack(spacing: HBSpacing.sm) {
                                        ForEach(RecurringInterval.allCases) { interval in
                                            Button(action: { recurringInterval = interval }) {
                                                Text(interval.rawValue)
                                                    .font(.system(size: 12, weight: recurringInterval == interval ? .semibold : .medium))
                                                    .foregroundColor(recurringInterval == interval ? .white : .hbPrimary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(recurringInterval == interval ? Color.hbPrimary : Color.hbPrimary.opacity(0.06))
                                                    .cornerRadius(HBRadii.chip)
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                        }
                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }

                                HBTextField(title: "Contractor (optional)", text: $contractorName, placeholder: "Name", icon: "person.fill")

                                if !contractorName.isEmpty {
                                    HStack(spacing: 4) {
                                        Text("Rating:")
                                            .font(.system(size: 13))
                                            .foregroundColor(.hbTextSecondary)
                                        ForEach(1...5, id: \.self) { star in
                                            Button(action: { contractorRating = star }) {
                                                Image(systemName: star <= contractorRating ? "star.fill" : "star")
                                                    .foregroundColor(.hbAmber)
                                                    .font(.system(size: 20))
                                            }
                                        }
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .padding(HBSpacing.md)
                            .background(Color.hbSurface)
                            .cornerRadius(HBRadii.card)

                            // Notes card
                            HBTextField(title: "Notes (optional)", text: $notes, placeholder: "Additional details...", icon: "note.text", isMultiline: true)
                                .padding(HBSpacing.md)
                                .background(Color.hbSurface)
                                .cornerRadius(HBRadii.card)
                        }
                        .padding(.horizontal, HBSpacing.lg)

                        HBButton(title: "Save Entry", isEnabled: isSaveEnabled) {
                            saveEntry()
                        }
                        .padding(.horizontal, HBSpacing.lg)

                        Spacer().frame(height: 100)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                if showingSaveAnimation {
                    SaveSuccessOverlay()
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.hbPrimary)
                }
            }
            .sheet(isPresented: $showFollowUpSheet) {
                FollowUpReminderSheet(
                    title: savedEntryTitle,
                    category: savedEntryCategory,
                    appStore: appStore
                )
                .presentationDetents([.medium])
            }
        }
        .onDisappear { saveTask?.cancel() }
    }

    private func saveEntry() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if !contractorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let contractor = Contractor(
                id: UUID(), userId: appStore.user.id,
                name: contractorName.trimmingCharacters(in: .whitespacesAndNewlines),
                specialty: category, rating: max(contractorRating, 1)
            )
            appStore.addContractor(contractor)
        }

        let entry = LogEntry(
            id: UUID(), homeId: appStore.currentHome.id, category: category,
            title: trimmedTitle, date: date, cost: parsedCost, priority: priority,
            recurringInterval: isRecurring ? recurringInterval : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photoURLs: []
        )

        savedEntryTitle = trimmedTitle
        savedEntryCategory = category
        appStore.addLog(entry)

        withAnimation(HBAnimation.springBounce) { showingSaveAnimation = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        saveTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(HBAnimation.transition) {
                    showingSaveAnimation = false
                    resetForm()
                }
                // Show follow-up reminder prompt
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFollowUpSheet = true
                }
            }
        }
    }

    private func resetForm() {
        title = ""; cost = ""; notes = ""; priority = .routine
        isRecurring = false; recurringInterval = nil
        contractorName = ""; contractorRating = 0; date = Date()
    }

    private func suggestionsFor(_ category: HomeCategory) -> [String] {
        switch category {
        case .hvac: return ["Changed HVAC filter", "AC tune-up", "Replaced thermostat"]
        case .plumbing: return ["Fixed leak", "Replaced faucet", "Flushed water heater"]
        case .electrical: return ["Replaced outlet", "Tested smoke detectors", "Changed light fixtures"]
        case .exterior: return ["Cleaned gutters", "Mowed lawn", "Pressure washed"]
        case .appliance: return ["Cleaned dishwasher", "Replaced fridge filter", "Dryer vent cleaned"]
        case .structural: return ["Patched drywall", "Caulked windows", "Inspected roof"]
        case .other: return ["General repair", "Home inspection", "Seasonal prep"]
        }
    }
}

// MARK: - Follow-Up Reminder Sheet
struct FollowUpReminderSheet: View {
    let title: String
    let category: HomeCategory
    let appStore: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedInterval: QuickInterval = .threeMonths
    @State private var customDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    enum QuickInterval: String, CaseIterable, Identifiable {
        case oneMonth = "1 month"
        case threeMonths = "3 months"
        case sixMonths = "6 months"
        case oneYear = "1 year"
        var id: String { rawValue }

        var date: Date {
            let cal = Calendar.current
            switch self {
            case .oneMonth: return cal.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            case .threeMonths: return cal.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            case .sixMonths: return cal.date(byAdding: .month, value: 6, to: Date()) ?? Date()
            case .oneYear: return cal.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            }
        }
    }

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.hbBorder)
                .frame(width: 36, height: 5)
                .padding(.top, HBSpacing.sm)

            VStack(spacing: HBSpacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.hbPrimary)

                Text("Schedule next check-in?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.hbTextPrimary)

                Text("Set a reminder for \"\(title)\"")
                    .font(.system(size: 14))
                    .foregroundColor(.hbTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Quick interval buttons
            HStack(spacing: HBSpacing.sm) {
                ForEach(QuickInterval.allCases) { interval in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedInterval = interval
                            customDate = interval.date
                        }
                    }) {
                        Text(interval.rawValue)
                            .font(.system(size: 13, weight: selectedInterval == interval ? .semibold : .medium))
                            .foregroundColor(selectedInterval == interval ? .white : .hbPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(selectedInterval == interval ? Color.hbPrimary : Color.hbPrimary.opacity(0.06))
                            .cornerRadius(HBRadii.chip)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, HBSpacing.lg)

            // Due date preview
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.hbPrimary)
                Text("Due: \(customDate.formatted(.dateTime.month(.wide).day().year()))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.hbTextPrimary)
            }
            .padding(HBSpacing.sm + 4)
            .background(Color.hbPrimary.opacity(0.04))
            .cornerRadius(10)

            Spacer()

            VStack(spacing: HBSpacing.sm) {
                HBButton(title: "Set Reminder") {
                    let reminder = Reminder(
                        id: UUID(),
                        homeId: appStore.currentHome.id,
                        title: title,
                        dueDate: customDate,
                        recurring: nil,
                        category: category
                    )
                    appStore.addReminder(reminder)
                    dismiss()
                }

                Button(action: { dismiss() }) {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.hbTextSecondary)
                        .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, HBSpacing.lg)
            .padding(.bottom, HBSpacing.lg)
        }
    }
}

// MARK: - Save Animation
struct SaveSuccessOverlay: View {
    @State private var confettiOpacity: Double = 0
    @State private var checkScale: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: HBSpacing.md) {
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        Circle()
                            .fill(i % 2 == 0 ? Color.hbPrimary : Color.hbLavender)
                            .frame(width: 7, height: 7)
                            .offset(
                                x: confettiOpacity > 0 ? cos(Double(i) * .pi / 6) * 48 : 0,
                                y: confettiOpacity > 0 ? sin(Double(i) * .pi / 6) * 48 : 0
                            )
                            .opacity(confettiOpacity)
                    }
                    Circle()
                        .fill(Color.hbPrimary)
                        .frame(width: 76, height: 76)
                        .scaleEffect(checkScale)
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkScale)
                }
                Text("Logged!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(checkScale)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Entry saved successfully")
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { checkScale = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { confettiOpacity = 1 }
            withAnimation(.easeIn(duration: 0.3).delay(0.7)) { confettiOpacity = 0 }
        }
    }
}
