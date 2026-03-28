import SwiftUI

// MARK: - Contractor List
struct ContractorListView: View {
    @Environment(AppStore.self) private var appStore
    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            GradientBackground()

            if appStore.contractors.isEmpty {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "No contractors yet",
                    subtitle: "Save contractors from your log entries"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.sm) {
                        ForEach(appStore.contractors) { contractor in
                            NavigationLink {
                                ContractorDetailView(contractor: contractor)
                            } label: {
                                ContractorRow(contractor: contractor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Contractors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.hbPrimary)
                }
                .accessibilityLabel("Add contractor")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContractorSheet()
                .environment(appStore)
        }
    }
}

// MARK: - Add Contractor Sheet
struct AddContractorSheet: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var specialty: HomeCategory = .plumbing
    @State private var rating: Int = 3

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        HBTextField(title: "Name", text: $name, placeholder: "Contractor name", icon: "person.fill")
                        HBTextField(title: "Phone", text: $phone, placeholder: "555-0123", icon: "phone.fill", keyboardType: .phonePad)
                        HBTextField(title: "Email", text: $email, placeholder: "email@example.com", icon: "envelope.fill", keyboardType: .emailAddress)

                        CategoryChipSelector(selected: $specialty)

                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Rating")
                                .font(HBTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(.hbTextSecondary)
                            HStack(spacing: HBSpacing.xs) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: { rating = star }) {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .foregroundColor(.hbElectrical)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                    }
                                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                                }
                            }
                        }

                        HBButton(title: "Save Contractor", isEnabled: isValid) {
                            let contractor = Contractor(
                                id: UUID(),
                                userId: appStore.user.id,
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                phone: phone.isEmpty ? nil : phone,
                                email: email.isEmpty ? nil : email,
                                specialty: specialty,
                                rating: rating
                            )
                            appStore.addContractor(contractor)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Contractor")
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

struct ContractorRow: View {
    let contractor: Contractor

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            ZStack {
                Circle()
                    .fill((contractor.specialty?.color ?? .hbPrimary).opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: contractor.specialty?.icon ?? "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(contractor.specialty?.color ?? .hbPrimary)
            }

            VStack(alignment: .leading, spacing: HBSpacing.xs) {
                Text(contractor.name)
                    .font(HBTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.hbTextPrimary)

                HStack(spacing: HBSpacing.sm) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= contractor.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(.hbElectrical)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(contractor.rating) out of 5 stars")
                    if let specialty = contractor.specialty {
                        Text(specialty.rawValue)
                            .font(HBTypography.caption)
                            .foregroundColor(.hbTextSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.hbBorder)
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Contractor Detail
struct ContractorDetailView: View {
    @Environment(AppStore.self) private var appStore
    let contractor: Contractor

    var contractorLogs: [LogEntry] {
        appStore.logs.filter { $0.contractorId == contractor.id }
    }

    var totalSpend: Double {
        contractorLogs.compactMap(\.cost).reduce(0, +)
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: HBSpacing.lg) {
                    VStack(spacing: HBSpacing.md) {
                        ZStack {
                            Circle()
                                .fill((contractor.specialty?.color ?? .hbPrimary).opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: contractor.specialty?.icon ?? "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(contractor.specialty?.color ?? .hbPrimary)
                        }

                        Text(contractor.name)
                            .font(HBTypography.h1)
                            .foregroundColor(.hbTextPrimary)

                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= contractor.rating ? "star.fill" : "star")
                                    .font(.system(size: 16))
                                    .foregroundColor(.hbElectrical)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(contractor.rating) out of 5 stars")
                    }

                    // Quick actions
                    HStack(spacing: HBSpacing.md) {
                        if contractor.phone != nil {
                            ContactAction(icon: "phone.fill", label: "Call", color: .hbPrimary)
                            ContactAction(icon: "message.fill", label: "Text", color: .hbPlumbing)
                        }
                        if contractor.email != nil {
                            ContactAction(icon: "envelope.fill", label: "Email", color: .hbHVAC)
                        }
                    }

                    HStack(spacing: HBSpacing.md) {
                        StatPill(title: "Jobs", value: "\(contractorLogs.count)", icon: "wrench.fill", color: .hbPrimary)
                        StatPill(title: "Total Spend", value: "$\(Int(totalSpend))", icon: "dollarsign.circle", color: .hbElectrical)
                    }

                    if !contractorLogs.isEmpty {
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Job History")
                                .font(HBTypography.h2)
                                .foregroundColor(.hbTextPrimary)

                            ForEach(contractorLogs) { log in
                                TimelineCard(entry: log)
                            }
                        }
                    }

                    Spacer().frame(height: HBSpacing.xxl)
                }
                .padding(.horizontal, HBSpacing.lg)
                .padding(.top, HBSpacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactAction: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            VStack(spacing: HBSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(HBTypography.caption)
                    .foregroundColor(.hbTextSecondary)
            }
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}
