import SwiftUI

struct OnboardingChallengeView: View {
    let store: OnboardingStore
    @State private var appeared = false
    @State private var heroRotation: Double = 0

    let challenges: [(icon: String, title: String, emoji: String)] = [
        ("clock.arrow.circlepath", "Forgetting maintenance", "🤔"),
        ("questionmark.diamond", "Not knowing what's needed", "❓"),
        ("chart.line.downtrend.xyaxis", "Tracking costs", "💸"),
        ("person.fill.questionmark", "Finding good contractors", "🔍"),
        ("exclamationmark.triangle.fill", "Urgent vs. can wait", "⚡"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HBSpacing.lg) {
                // Puzzle hero
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.hbBorder.opacity(0.1), lineWidth: 1.5)
                            .frame(width: 60 + CGFloat(i) * 22, height: 60 + CGFloat(i) * 22)
                            .rotationEffect(.degrees(heroRotation + Double(i) * 15))
                    }
                    ZStack {
                        Circle().fill(Color.hbSurfaceMint).frame(width: 60, height: 60)
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(LinearGradient(colors: [.hbPrimary, .hbPrimaryDark], startPoint: .top, endPoint: .bottom))
                    }
                }
                .frame(height: 115)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.6)
                .padding(.top, HBSpacing.sm)

                VStack(spacing: HBSpacing.xs) {
                    Text("What's your biggest\nchallenge?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.hbTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Text("Tap the one that resonates most")
                        .font(HBTypography.bodySmall)
                        .foregroundColor(.hbTextSecondary)
                }
                .opacity(appeared ? 1 : 0)

                // Emoji + text rows — lightweight, no heavy card chrome
                VStack(spacing: HBSpacing.sm + 2) {
                    ForEach(Array(challenges.enumerated()), id: \.element.title) { index, c in
                        let isSelected = store.responses.biggestChallenge == c.title

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                store.responses.biggestChallenge = c.title
                            }
                        }) {
                            HStack(spacing: HBSpacing.md) {
                                Text(c.emoji)
                                    .font(.system(size: 26))
                                    .frame(width: 46, height: 46)
                                    .background(
                                        Circle().fill(isSelected ? Color.hbPrimary.opacity(0.1) : Color.hbLavender.opacity(0.06))
                                    )
                                    .scaleEffect(isSelected ? 1.1 : 1)

                                Text(c.title)
                                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .hbPrimary : .hbTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if isSelected {
                                    Circle()
                                        .fill(Color.hbPrimary)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, HBSpacing.md)
                            .padding(.vertical, HBSpacing.sm + 2)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isSelected ? Color.hbPrimary.opacity(0.04) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Color.hbPrimary.opacity(0.25) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : (index.isMultiple(of: 2) ? -18 : 18))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.12 + Double(index) * 0.05), value: appeared)
                    }
                }
                .padding(.horizontal, HBSpacing.lg)

                Spacer().frame(height: HBSpacing.md)

                HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.bottom, HBSpacing.xxl)
            }
        }
        .onAppear {
            withAnimation(HBAnimation.springGentle) { appeared = true }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { heroRotation = 360 }
        }
    }
}
