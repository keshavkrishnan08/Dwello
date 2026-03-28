import SwiftUI

struct LogDetailView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    let entry: LogEntry
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var appeared = false

    var contractor: Contractor? {
        guard let id = entry.contractorId else { return nil }
        return appStore.contractors.first { $0.id == id }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: HBSpacing.lg) {
                    // Header card
                    VStack(spacing: HBSpacing.md) {
                        // Category badge
                        HStack {
                            HStack(spacing: HBSpacing.sm) {
                                Image(systemName: entry.category.icon)
                                    .font(.system(size: 16))
                                Text(entry.category.rawValue)
                                    .font(HBTypography.chip)
                            }
                            .foregroundColor(entry.category.color)
                            .padding(.horizontal, HBSpacing.md)
                            .padding(.vertical, HBSpacing.sm)
                            .background(entry.category.color.opacity(0.12))
                            .cornerRadius(HBRadii.chip)

                            Spacer()

                            // Priority badge
                            Text(entry.priority.rawValue)
                                .font(HBTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(entry.priority.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, HBSpacing.xs)
                                .background(entry.priority.color.opacity(0.12))
                                .cornerRadius(HBRadii.badge)
                        }

                        Text(entry.title)
                            .font(HBTypography.h1)
                            .foregroundColor(.hbTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Date and cost
                        HStack(spacing: HBSpacing.lg) {
                            DetailItem(icon: "calendar", label: "Date",
                                       value: entry.date.formatted(.dateTime.month(.wide).day().year()))

                            if let cost = entry.cost, cost > 0 {
                                DetailItem(icon: "dollarsign.circle", label: "Cost",
                                           value: "$\(String(format: "%.2f", cost))")
                            }
                        }
                    }
                    .padding(HBSpacing.lg)
                    .background(Color.hbSurface)
                    .cornerRadius(HBRadii.card)
                    .hbShadow(.sm)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    // Photos section (placeholder)
                    if !entry.photoURLs.isEmpty {
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Photos")
                                .font(HBTypography.h2)
                                .foregroundColor(.hbTextPrimary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: HBSpacing.sm) {
                                    ForEach(entry.photoURLs, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: HBRadii.input)
                                            .fill(Color.hbBorder.opacity(0.3))
                                            .frame(width: 120, height: 120)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.hbTextSecondary)
                                            )
                                    }
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(HBAnimation.springGentle.delay(0.1), value: appeared)
                    }

                    // Notes section
                    if let notes = entry.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Notes")
                                .font(HBTypography.h2)
                                .foregroundColor(.hbTextPrimary)

                            Text(notes)
                                .font(HBTypography.body)
                                .foregroundColor(.hbTextSecondary)
                                .padding(HBSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.hbSurface)
                                .cornerRadius(HBRadii.card)
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(HBAnimation.springGentle.delay(0.2), value: appeared)
                    }

                    // Contractor
                    if let contractor = contractor {
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Contractor")
                                .font(HBTypography.h2)
                                .foregroundColor(.hbTextPrimary)

                            NavigationLink {
                                ContractorDetailView(contractor: contractor)
                            } label: {
                                HStack(spacing: HBSpacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.hbPrimaryLight)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.hbPrimary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contractor.name)
                                            .font(HBTypography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.hbTextPrimary)
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: star <= contractor.rating ? "star.fill" : "star")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.hbElectrical)
                                            }
                                        }
                                    }

                                    Spacer()

                                    HStack(spacing: HBSpacing.sm) {
                                        if let _ = contractor.phone {
                                            Button(action: {}) {
                                                Image(systemName: "phone.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.hbPrimary)
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.hbPrimaryLight)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                }
                                .padding(HBSpacing.md)
                                .background(Color.hbSurface)
                                .cornerRadius(HBRadii.card)
                                .hbShadow(.sm)
                            }
                            .buttonStyle(.plain)
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(HBAnimation.springGentle.delay(0.3), value: appeared)
                    }

                    // Recurring info
                    if let interval = entry.recurringInterval {
                        HStack(spacing: HBSpacing.md) {
                            Image(systemName: "repeat")
                                .foregroundColor(.hbPrimary)
                            Text("Repeats \(interval.rawValue.lowercased())")
                                .font(HBTypography.body)
                                .foregroundColor(.hbTextPrimary)
                            Spacer()
                        }
                        .padding(HBSpacing.md)
                        .background(Color.hbSurface)
                        .cornerRadius(HBRadii.card)
                        .hbShadow(.sm)
                    }

                    // Warranty
                    if let warranty = entry.warrantyExpiry {
                        HStack(spacing: HBSpacing.md) {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(warranty > Date() ? .hbPrimary : .hbDanger)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Warranty")
                                    .font(HBTypography.body)
                                    .foregroundColor(.hbTextPrimary)
                                Text(warranty > Date() ? "Expires \(warranty.formatted(.dateTime.month(.abbreviated).day().year()))" : "Expired")
                                    .font(HBTypography.caption)
                                    .foregroundColor(warranty > Date() ? .hbTextSecondary : .hbDanger)
                            }
                            Spacer()
                        }
                        .padding(HBSpacing.md)
                        .background(Color.hbSurface)
                        .cornerRadius(HBRadii.card)
                        .hbShadow(.sm)
                    }

                    // Actions
                    HStack(spacing: HBSpacing.md) {
                        HBButton(title: "Edit", style: .secondary) {
                            showEditSheet = true
                        }

                        Button(action: { showDeleteAlert = true }) {
                            Text("Delete")
                                .font(HBTypography.button)
                                .foregroundColor(.hbDanger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.hbDanger.opacity(0.1))
                                .cornerRadius(HBRadii.button)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.top, HBSpacing.md)

                    Spacer().frame(height: HBSpacing.xxl)
                }
                .padding(.horizontal, HBSpacing.lg)
                .padding(.top, HBSpacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Entry", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                appStore.deleteLog(entry)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this log entry? This action cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            EditLogSheet(entry: entry)
                .environment(appStore)
        }
        .onAppear {
            withAnimation(HBAnimation.springGentle) {
                appeared = true
            }
        }
    }
}

// MARK: - Edit Log Sheet
struct EditLogSheet: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    let entry: LogEntry

    @State private var category: HomeCategory
    @State private var title: String
    @State private var date: Date
    @State private var cost: String
    @State private var notes: String
    @State private var priority: Priority
    @State private var isRecurring: Bool
    @State private var recurringInterval: RecurringInterval?
    @State private var contractorName: String = ""
    @State private var contractorRating: Int = 0

    init(entry: LogEntry) {
        self.entry = entry
        _category = State(initialValue: entry.category)
        _title = State(initialValue: entry.title)
        _date = State(initialValue: entry.date)
        _cost = State(initialValue: entry.cost.map { String(format: "%.2f", $0) } ?? "")
        _notes = State(initialValue: entry.notes ?? "")
        _priority = State(initialValue: entry.priority)
        _isRecurring = State(initialValue: entry.recurringInterval != nil)
        _recurringInterval = State(initialValue: entry.recurringInterval)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        LogEntryForm(
                            category: $category,
                            title: $title,
                            date: $date,
                            cost: $cost,
                            notes: $notes,
                            priority: $priority,
                            isRecurring: $isRecurring,
                            recurringInterval: $recurringInterval,
                            contractorName: $contractorName,
                            contractorRating: $contractorRating
                        )

                        HBButton(title: "Save Changes", isEnabled: isValid) {
                            if let index = appStore.logs.firstIndex(where: { $0.id == entry.id }) {
                                let cleaned = cost.replacingOccurrences(of: ",", with: "")
                                appStore.logs[index].category = category
                                appStore.logs[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                                appStore.logs[index].date = date
                                appStore.logs[index].cost = Double(cleaned)
                                appStore.logs[index].notes = notes.isEmpty ? nil : notes
                                appStore.logs[index].priority = priority
                                appStore.logs[index].recurringInterval = isRecurring ? recurringInterval : nil
                            }
                            dismiss()
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Entry")
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

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: HBSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.hbTextSecondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(HBTypography.caption)
                    .foregroundColor(.hbTextSecondary)
                Text(value)
                    .font(HBTypography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextPrimary)
            }
        }
    }
}
