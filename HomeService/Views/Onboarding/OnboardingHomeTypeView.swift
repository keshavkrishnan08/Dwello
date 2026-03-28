import SwiftUI

struct OnboardingHomeTypeView: View {
    let store: OnboardingStore
    @State private var appeared = false

    private let types = Home.HomeType.allCases

    var body: some View {
        VStack(spacing: HBSpacing.xl) {
            Spacer().frame(height: HBSpacing.md)

            // Hero — morphing icon in teal circle
            ZStack {
                Circle()
                    .fill(Color.hbSurfaceMint)
                    .frame(width: 130, height: 130)
                    .scaleEffect(appeared ? 1 : 0.3)

                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Color.hbPrimary.opacity(0.2))
                        .frame(width: CGFloat.random(in: 4...7))
                        .offset(
                            x: appeared ? cos(Double(i) * .pi / 2.5) * 60 : 0,
                            y: appeared ? sin(Double(i) * .pi / 2.5) * 60 : 0
                        )
                        .animation(.easeOut(duration: 0.9).delay(Double(i) * 0.06), value: appeared)
                }

                if let sel = store.responses.homeType {
                    Image(systemName: sel.icon)
                        .font(.system(size: 52, weight: .thin))
                        .foregroundColor(.hbPrimary)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                        .id(sel.rawValue)
                } else {
                    Image(systemName: "house.fill")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.hbBorder)
                        .opacity(0.4)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: store.responses.homeType)
            .opacity(appeared ? 1 : 0)

            Text("What type of home\ndo you have?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.hbTextPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            // Staggered icon bubbles — 2 columns offset
            HStack(alignment: .top, spacing: HBSpacing.lg) {
                VStack(spacing: HBSpacing.md) {
                    typeBubble(types[0], index: 0)
                    typeBubble(types[2], index: 2)
                    typeBubble(types[4], index: 4)
                }

                VStack(spacing: HBSpacing.md) {
                    Spacer().frame(height: 30)
                    typeBubble(types[1], index: 1)
                    typeBubble(types[3], index: 3)
                }
            }
            .padding(.horizontal, HBSpacing.xl)

            Spacer()

            HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                .padding(.horizontal, HBSpacing.lg)
                .padding(.bottom, HBSpacing.xxl)
        }
        .onAppear { withAnimation(HBAnimation.springGentle) { appeared = true } }
    }

    @ViewBuilder
    private func typeBubble(_ type: Home.HomeType, index: Int) -> some View {
        let isSelected = store.responses.homeType == type
        let color: Color = isSelected ? .hbPrimary : .hbLavender

        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                store.responses.homeType = type
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.hbPrimary.opacity(0.12) : Color.hbLavender.opacity(0.06))
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle().stroke(isSelected ? Color.hbPrimary : Color.hbLavender.opacity(0.25), lineWidth: isSelected ? 2.5 : 1)
                        )
                        .scaleEffect(isSelected ? 1.08 : 1)

                    Image(systemName: type.icon)
                        .font(.system(size: 26))
                        .foregroundColor(color)
                }

                Text(type.rawValue.components(separatedBy: " / ").first ?? type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .hbPrimary : .hbTextSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.12 + Double(index) * 0.06), value: appeared)
    }
}
