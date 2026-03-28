import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var floating = false

    var body: some View {
        VStack(spacing: HBSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.hbPrimaryLight)
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.hbPrimary)
            }
            .offset(y: floating ? -5 : 5)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: floating)

            Text(title)
                .font(HBTypography.h2)
                .foregroundColor(.hbTextPrimary)

            Text(subtitle)
                .font(HBTypography.body)
                .foregroundColor(.hbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .onAppear { floating = true }
    }
}
