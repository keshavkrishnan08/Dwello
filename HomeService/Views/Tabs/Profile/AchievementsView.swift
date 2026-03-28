import SwiftUI

struct AchievementsView: View {
    @Environment(AppStore.self) private var appStore
    @State private var appeared = false

    private var unlockedCount: Int {
        appStore.achievements.filter(\.isUnlocked).count
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: HBSpacing.lg) {
                    // Header stats
                    VStack(spacing: HBSpacing.sm) {
                        Text("\(unlockedCount)/\(appStore.achievements.count)")
                            .font(HBTypography.statNumber)
                            .foregroundColor(.hbPrimary)

                        Text("Achievements Unlocked")
                            .font(HBTypography.body)
                            .foregroundColor(.hbTextSecondary)

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.hbBorder.opacity(0.3))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.hbPrimary)
                                    .frame(
                                        width: geo.size.width * (Double(unlockedCount) / Double(max(appStore.achievements.count, 1))),
                                        height: 8
                                    )
                                    .animation(.easeOut(duration: 0.8), value: appeared)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, HBSpacing.xl)
                    }
                    .padding(.top, HBSpacing.md)

                    // Achievement grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: HBSpacing.md),
                        GridItem(.flexible(), spacing: HBSpacing.md),
                    ], spacing: HBSpacing.md) {
                        ForEach(Array(appStore.achievements.enumerated()), id: \.element.id) { index, achievement in
                            AchievementCard(achievement: achievement)
                                .opacity(appeared ? 1 : 0)
                                .scaleEffect(appeared ? 1 : 0.8)
                                .animation(
                                    HBAnimation.springBounce.delay(Double(index) * 0.06),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)

                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationTitle("Achievements")
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var unlockAnimation = false

    var body: some View {
        VStack(spacing: HBSpacing.sm) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.hbPrimaryLight : Color.hbBorder.opacity(0.2))
                    .frame(width: 64, height: 64)

                if achievement.isUnlocked {
                    // Gold particle burst (simplified)
                    Circle()
                        .stroke(Color.hbElectrical.opacity(unlockAnimation ? 0 : 0.5), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(unlockAnimation ? 1.3 : 1)
                }

                Image(systemName: achievement.type.icon)
                    .font(.system(size: 26))
                    .foregroundColor(achievement.isUnlocked ? .hbPrimary : .hbBorder)
                    .rotationEffect(.degrees(achievement.isUnlocked && unlockAnimation ? 0 : (achievement.isUnlocked ? 10 : 0)))
            }

            Text(achievement.type.rawValue)
                .font(HBTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .hbTextPrimary : .hbTextSecondary)
                .multilineTextAlignment(.center)

            Text(achievement.type.description)
                .font(HBTypography.caption)
                .foregroundColor(.hbTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let date = achievement.unlockedAt {
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.hbPrimary)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.hbBorder)
            }
        }
        .padding(HBSpacing.md)
        .background(Color.hbSurface)
        .cornerRadius(HBRadii.card)
        .hbShadow(.sm)
        .opacity(achievement.isUnlocked ? 1 : 0.7)
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.5)) {
                    unlockAnimation = true
                }
            }
        }
    }
}
