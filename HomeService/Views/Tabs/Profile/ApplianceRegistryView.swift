import SwiftUI

struct ApplianceRegistryView: View {
    @Environment(AppStore.self) private var appStore
    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            GradientBackground()

            if appStore.appliances.isEmpty {
                EmptyStateView(
                    icon: "gearshape.2.fill",
                    title: "No appliances registered",
                    subtitle: "Track your appliances, warranties, and manuals"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.sm) {
                        ForEach(appStore.appliances) { appliance in
                            ApplianceCard(appliance: appliance)
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Appliances")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.hbPrimary)
                }
                .accessibilityLabel("Add appliance")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddApplianceSheet()
                .environment(appStore)
        }
    }
}

// MARK: - Add Appliance Sheet
struct AddApplianceSheet: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var make = ""
    @State private var model = ""
    @State private var purchaseDate = Date()
    @State private var hasWarranty = false
    @State private var warrantyExpiry = Date()

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.lg) {
                        HBTextField(title: "Name", text: $name, placeholder: "e.g., Dishwasher", icon: "gearshape.fill")
                        HBTextField(title: "Make", text: $make, placeholder: "e.g., Bosch")
                        HBTextField(title: "Model", text: $model, placeholder: "e.g., SHP88PZ55N")

                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            Text("Purchase Date")
                                .font(HBTypography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(.hbTextSecondary)
                            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.hbPrimary)
                        }

                        Toggle(isOn: $hasWarranty) {
                            Text("Has warranty")
                                .font(HBTypography.body)
                                .foregroundColor(.hbTextPrimary)
                        }
                        .tint(.hbPrimary)

                        if hasWarranty {
                            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                                Text("Warranty Expiry")
                                    .font(HBTypography.bodySmall)
                                    .fontWeight(.medium)
                                    .foregroundColor(.hbTextSecondary)
                                DatePicker("", selection: $warrantyExpiry, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(.hbPrimary)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        HBButton(title: "Save Appliance", isEnabled: isValid) {
                            let appliance = Appliance(
                                id: UUID(),
                                homeId: appStore.currentHome.id,
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                make: make.isEmpty ? nil : make,
                                model: model.isEmpty ? nil : model,
                                purchaseDate: purchaseDate,
                                warrantyExpiry: hasWarranty ? warrantyExpiry : nil
                            )
                            appStore.addAppliance(appliance)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Appliance")
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

struct ApplianceCard: View {
    let appliance: Appliance

    var warrantyStatus: (String, Color) {
        guard let expiry = appliance.warrantyExpiry else { return ("No warranty", .hbTextSecondary) }
        if expiry > Date() {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
            return ("Warranty: \(days) days left", .hbPrimary)
        }
        return ("Warranty expired", .hbDanger)
    }

    var age: String {
        guard let purchase = appliance.purchaseDate else { return "" }
        let years = Calendar.current.dateComponents([.year], from: purchase, to: Date()).year ?? 0
        return "\(years) years old"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.md) {
            HStack(spacing: HBSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.hbAppliance.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.hbAppliance)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appliance.name)
                        .font(HBTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.hbTextPrimary)

                    if let make = appliance.make, let model = appliance.model {
                        Text("\(make) \(model)")
                            .font(HBTypography.bodySmall)
                            .foregroundColor(.hbTextSecondary)
                    }
                }

                Spacer()

                if !age.isEmpty {
                    Text(age)
                        .font(HBTypography.caption)
                        .foregroundColor(.hbTextSecondary)
                }
            }

            // Warranty status
            HStack(spacing: HBSpacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 12))
                    .foregroundColor(warrantyStatus.1)
                Text(warrantyStatus.0)
                    .font(HBTypography.caption)
                    .foregroundColor(warrantyStatus.1)

                Spacer()

                if let purchase = appliance.purchaseDate {
                    Text("Purchased \(purchase.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(HBTypography.caption)
                        .foregroundColor(.hbTextSecondary)
                }
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
    }
}
