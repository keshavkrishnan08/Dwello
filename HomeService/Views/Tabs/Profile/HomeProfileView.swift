import SwiftUI

struct HomeProfileView: View {
    @Environment(AppStore.self) private var appStore
    @State private var appeared = false

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: HBSpacing.lg) {
                    // Home image placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: HBRadii.card)
                            .fill(Color.hbPrimaryLight.opacity(0.5))
                            .frame(height: 200)

                        VStack(spacing: HBSpacing.sm) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.hbPrimary)
                            Text("Add Home Photo")
                                .font(HBTypography.bodySmall)
                                .foregroundColor(.hbPrimary)
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    // Home details card
                    VStack(spacing: HBSpacing.md) {
                        HomeDetailRow(label: "Name", value: appStore.currentHome.name)
                        Divider()
                        HomeDetailRow(label: "Type", value: appStore.currentHome.type.rawValue)
                        Divider()
                        if let year = appStore.currentHome.yearBuilt {
                            HomeDetailRow(label: "Year Built", value: "\(year)")
                            Divider()
                        }
                        if let sqft = appStore.currentHome.sqft {
                            HomeDetailRow(label: "Square Feet", value: "\(sqft) sq ft")
                            Divider()
                        }
                        HomeDetailRow(label: "Address", value: appStore.currentHome.address ?? "Not set")
                    }
                    .padding(HBSpacing.lg)
                    .background(Color.hbSurface)
                    .cornerRadius(HBRadii.card)
                    .hbShadow(.sm)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(HBAnimation.springGentle.delay(0.1), value: appeared)

                    // Quick stats
                    VStack(alignment: .leading, spacing: HBSpacing.md) {
                        Text("Home Stats")
                            .font(HBTypography.h2)
                            .foregroundColor(.hbTextPrimary)

                        HStack(spacing: HBSpacing.md) {
                            StatPill(title: "Total Logs", value: "\(appStore.logs.count)", icon: "doc.text.fill", color: .hbPrimary)
                            StatPill(title: "Total Spent", value: "$\(Int(appStore.totalSpend))", icon: "dollarsign.circle", color: .hbElectrical)
                            StatPill(title: "Contractors", value: "\(appStore.contractors.count)", icon: "person.2.fill", color: .hbHVAC)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(HBAnimation.springGentle.delay(0.2), value: appeared)

                    // Edit button
                    HBButton(title: "Edit Home Profile", style: .secondary) {}

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, HBSpacing.lg)
                .padding(.top, HBSpacing.md)
            }
        }
        .navigationTitle("Home Profile")
        .onAppear {
            withAnimation(HBAnimation.springGentle) {
                appeared = true
            }
        }
    }
}

struct HomeDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(HBTypography.body)
                .foregroundColor(.hbTextSecondary)
            Spacer()
            Text(value)
                .font(HBTypography.body)
                .fontWeight(.medium)
                .foregroundColor(.hbTextPrimary)
        }
    }
}
