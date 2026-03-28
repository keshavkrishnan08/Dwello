import SwiftUI
import StoreKit

struct OnboardingContainerView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var store = OnboardingStore()

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 0) {
                // Hide nav on loading/paywall screens
                if store.currentStep > 1 && store.currentStep < 11 {
                    HStack {
                        Button(action: { store.previousStep() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.hbTextSecondary)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, HBSpacing.sm)
                    HBProgressBar(currentStep: store.currentStep, totalSteps: store.totalSteps)
                        .padding(.bottom, HBSpacing.sm)
                }
                Group {
                    switch store.currentStep {
                    case 1:  WelcomeStep(store: store)
                    case 2:  OnboardingHomeTypeView(store: store)
                    case 3:  HomeAgeStep(store: store)
                    case 4:  FrequencyStep(store: store)
                    case 5:  SystemsStep(store: store)
                    case 6:  GoalsStep(store: store)
                    case 7:  OnboardingChallengeView(store: store)
                    case 8:  ExistingSystemsStep(store: store)
                    case 9:  NotificationStep(store: store)
                    case 10: PersonalizedStep(store: store)
                    case 11: LoadingPlanStep(store: store)
                    case 12: PaywallStep(store: store)
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onChange(of: store.isComplete) { _, done in if done { isOnboardingComplete = true } }
    }
}

// MARK: - 1: Welcome
private struct WelcomeStep: View {
    let store: OnboardingStore
    @State private var appeared = false
    @State private var houseFloat: CGFloat = 0
    @State private var orbitAngle: Double = 0

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer()
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.hbPrimary.opacity(0.05 - Double(i) * 0.012), lineWidth: 1.5)
                        .frame(width: 140 + CGFloat(i) * 55)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.easeOut(duration: 0.9).delay(Double(i) * 0.1), value: appeared)
                }
                ForEach(0..<4, id: \.self) { i in
                    let icons = ["wrench.fill", "hammer.fill", "paintbrush.fill", "leaf.fill"]
                    let angle = orbitAngle + Double(i) * 90
                    ZStack {
                        Circle().fill(i % 2 == 0 ? Color.hbPrimary.opacity(0.08) : Color.hbLavender.opacity(0.08))
                            .frame(width: 32)
                        Image(systemName: icons[i]).font(.system(size: 13))
                            .foregroundColor(i % 2 == 0 ? .hbPrimary : .hbLavender)
                    }
                    .offset(x: cos(angle * .pi / 180) * 100, y: sin(angle * .pi / 180) * 45)
                    .scaleEffect(appeared ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.35 + Double(i) * 0.08), value: appeared)
                }
                Ellipse().fill(Color.hbPrimary.opacity(0.04)).frame(width: 90, height: 16).offset(y: 58)
                VStack(spacing: 0) {
                    ZStack {
                        Triangle().fill(Color.hbPrimaryDark.opacity(0.18)).frame(width: 100, height: 44).offset(x: 3, y: 3)
                        Triangle().fill(LinearGradient(colors: [.hbPrimary, .hbPrimaryDark], startPoint: .top, endPoint: .bottom))
                            .frame(width: 100, height: 44)
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.white, Color.hbSurfaceWarm], startPoint: .top, endPoint: .bottom))
                            .frame(width: 82, height: 52)
                        RoundedRectangle(cornerRadius: 3).fill(Color.hbPrimary).frame(width: 16, height: 28).offset(y: 12)
                        Circle().fill(Color.hbLavender).frame(width: 3, height: 3).offset(x: 5, y: 12)
                        HStack(spacing: 12) { WindowPane(); Spacer().frame(width: 16); WindowPane() }.offset(y: -6)
                    }.offset(y: -2)
                }
                .offset(y: houseFloat)
                .scaleEffect(appeared ? 1 : 0.3)
                .animation(.spring(response: 0.7, dampingFraction: 0.6), value: appeared)
            }
            .frame(height: 240)

            VStack(spacing: HBSpacing.md) {
                Text("Welcome to\nHomeBase")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.hbTextPrimary)
                    .multilineTextAlignment(.center).lineSpacing(4)
                Text("Track, manage, and protect\nyour biggest investment.")
                    .font(HBTypography.body).foregroundColor(.hbTextSecondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, HBSpacing.lg)
            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)
            Spacer()
            HBButton(title: "Get Started") { store.nextStep() }
                .padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
                .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
        }
        .onAppear {
            withAnimation { appeared = true }
            withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) { orbitAngle = 360 }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { houseFloat = -7 }
        }
    }
}

// MARK: - 3: Home Age
private struct HomeAgeStep: View {
    let store: OnboardingStore
    @State private var appeared = false

    private let ages: [(OnboardingResponses.HomeAge, String, String)] = [
        (.newBuild, "🏗️", "0–5 yrs"),
        (.established, "🏠", "5–20 yrs"),
        (.mature, "🏡", "20–50 yrs"),
        (.historic, "🏛️", "50+ yrs"),
    ]

    var body: some View {
        VStack(spacing: HBSpacing.xl) {
            Spacer().frame(height: HBSpacing.lg)

            ZStack {
                HalfArc().stroke(Color.hbBorder.opacity(0.2), style: StrokeStyle(lineWidth: 2.5, dash: [8, 6]))
                    .frame(width: 240, height: 70)
                HalfArc().trim(from: 0, to: appeared ? 1 : 0)
                    .stroke(LinearGradient(colors: [.hbPrimary, .hbLavender], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 240, height: 70)
                    .animation(.easeOut(duration: 1.3).delay(0.3), value: appeared)
                ForEach(0..<4, id: \.self) { i in
                    let t = Double(i) / 3.0; let angle = Double.pi * (1 - t)
                    Circle().fill(i % 2 == 0 ? Color.hbPrimary : Color.hbLavender).frame(width: 8)
                        .offset(x: cos(angle) * 120, y: -sin(angle) * 70 + 18)
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5 + Double(i) * 0.12), value: appeared)
                }
            }.frame(height: 100).opacity(appeared ? 1 : 0)

            Text("How old is your home?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.hbTextPrimary).opacity(appeared ? 1 : 0)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: HBSpacing.md), GridItem(.flexible(), spacing: HBSpacing.md)], spacing: HBSpacing.md) {
                ForEach(Array(ages.enumerated()), id: \.element.0) { index, age in
                    let isSelected = store.responses.homeAge == age.0
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { store.responses.homeAge = age.0 }
                    }) {
                        VStack(spacing: HBSpacing.sm) {
                            Text(age.1).font(.system(size: isSelected ? 40 : 34)).scaleEffect(isSelected ? 1.05 : 1)
                            Text(age.2).font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .hbPrimary : .hbTextSecondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, HBSpacing.lg)
                        .background(isSelected ? Color.hbPrimary.opacity(0.04) : Color.hbSurfaceWarm)
                        .cornerRadius(HBRadii.card)
                        .overlay(RoundedRectangle(cornerRadius: HBRadii.card).stroke(isSelected ? Color.hbPrimary : .clear, lineWidth: 2))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(appeared ? 1 : 0).scaleEffect(appeared ? 1 : 0.85)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2 + Double(index) * 0.06), value: appeared)
                }
            }.padding(.horizontal, HBSpacing.lg)

            if let sel = store.responses.homeAge {
                Text(descFor(sel)).font(HBTypography.bodySmall).foregroundColor(.hbTextSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, HBSpacing.xl).transition(.opacity)
            }
            Spacer()
            HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                .padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
        }
        .onAppear { withAnimation(HBAnimation.springGentle) { appeared = true } }
    }
    private func descFor(_ a: OnboardingResponses.HomeAge) -> String {
        switch a {
        case .newBuild: return "Mostly warranty-covered. Focus on documenting."
        case .established: return "Preventive maintenance saves thousands."
        case .mature: return "Major replacements coming. Budget now."
        case .historic: return "Extra care for character and charm."
        }
    }
}

// MARK: - 4: Frequency
private struct FrequencyStep: View {
    let store: OnboardingStore
    @State private var appeared = false

    private let freqs: [(OnboardingResponses.MaintenanceFrequency, String, [CGFloat])] = [
        (.regularly, "Monthly+", [0.8, 0.9, 0.7, 0.85, 0.9, 0.6, 0.75]),
        (.sometimes, "Quarterly", [0.2, 0.1, 0.1, 0.7, 0.1, 0.1, 0.6]),
        (.rarely, "Yearly", [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.8]),
        (.whenBreaks, "Reactive", [0.0, 0.0, 0.0, 0.95, 0.0, 0.0, 0.0]),
        (.justMoved, "New here", [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
    ]
    private var activeBars: [CGFloat] {
        guard let sel = store.responses.frequency, let m = freqs.first(where: { $0.0 == sel }) else {
            return [0.3, 0.5, 0.4, 0.6, 0.3, 0.7, 0.2]
        }; return m.2
    }
    var body: some View {
        VStack(spacing: HBSpacing.xl) {
            Spacer().frame(height: HBSpacing.md)
            Text("How often do you\ndo maintenance?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.hbTextPrimary).multilineTextAlignment(.center).lineSpacing(4).opacity(appeared ? 1 : 0)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<7, id: \.self) { i in
                    let days = ["M", "T", "W", "T", "F", "S", "S"]
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(LinearGradient(colors: [.hbPrimary.opacity(0.5), .hbPrimary], startPoint: .top, endPoint: .bottom))
                            .frame(width: 26, height: max(4, appeared ? activeBars[i] * 75 : 4))
                            .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(Double(i) * 0.03), value: store.responses.frequency)
                            .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15 + Double(i) * 0.05), value: appeared)
                        Text(days[i]).font(.system(size: 11, weight: .medium)).foregroundColor(.hbTextSecondary)
                    }
                }
            }.frame(height: 105).padding(HBSpacing.md).background(Color.hbSurface).cornerRadius(HBRadii.card).hbShadow(.sm)
            .padding(.horizontal, HBSpacing.xl)

            VStack(spacing: HBSpacing.sm) {
                HStack(spacing: HBSpacing.sm) { freqPill(freqs[0], 0); freqPill(freqs[1], 1); freqPill(freqs[2], 2) }
                HStack(spacing: HBSpacing.sm) { freqPill(freqs[3], 3); freqPill(freqs[4], 4) }
            }.padding(.horizontal, HBSpacing.lg)
            Spacer()
            HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                .padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
        }
        .onAppear { withAnimation { appeared = true } }
    }
    @ViewBuilder private func freqPill(_ f: (OnboardingResponses.MaintenanceFrequency, String, [CGFloat]), _ i: Int) -> some View {
        let sel = store.responses.frequency == f.0
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { store.responses.frequency = f.0 }
        }) {
            Text(f.1).font(.system(size: 14, weight: sel ? .semibold : .medium))
                .foregroundColor(sel ? .white : .hbPrimary).frame(maxWidth: .infinity)
                .padding(.vertical, HBSpacing.sm + 4)
                .background(sel ? Color.hbPrimary : Color.hbPrimary.opacity(0.06)).cornerRadius(HBRadii.chip)
        }.buttonStyle(ScaleButtonStyle()).opacity(appeared ? 1 : 0)
        .animation(HBAnimation.springGentle.delay(0.12 + Double(i) * 0.04), value: appeared)
    }
}

// MARK: - 5: Systems
private struct SystemsStep: View {
    let store: OnboardingStore
    @State private var appeared = false
    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer().frame(height: HBSpacing.md)
            Text("Which areas do you\nwant to track?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.hbTextPrimary).multilineTextAlignment(.center).lineSpacing(4).opacity(appeared ? 1 : 0)
            Text("Tap to toggle — change anytime").font(HBTypography.bodySmall).foregroundColor(.hbTextSecondary)
            CircularCategorySelector(selectedCategories: Binding(
                get: { store.responses.selectedSystems }, set: { store.responses.selectedSystems = $0 }
            )).opacity(appeared ? 1 : 0)
            Spacer()
            HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                .padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
        }
        .onAppear { withAnimation(HBAnimation.springGentle) { appeared = true } }
    }
}

// MARK: - 6: Goals — 3-column grid with labels, compact
private struct GoalsStep: View {
    let store: OnboardingStore
    @State private var appeared = false

    let goals: [(String, String)] = [
        ("Save money", "dollarsign.circle.fill"),
        ("Home value", "chart.line.uptrend.xyaxis"),
        ("Prevent emergencies", "shield.checkered"),
        ("Stay organized", "checklist"),
        ("Track spending", "creditcard.fill"),
        ("Good contractors", "person.badge.plus"),
        ("Seasonal reminders", "leaf.fill"),
        ("Warranty tracking", "doc.badge.clock.fill"),
        ("Learn basics", "book.fill"),
    ]

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer().frame(height: HBSpacing.sm)

            Text("What are your goals?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.hbTextPrimary).opacity(appeared ? 1 : 0)

            Text("Tap as many as you'd like")
                .font(HBTypography.bodySmall).foregroundColor(.hbTextSecondary)

            // Compact 3-column grid — icons with labels
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HBSpacing.md), count: 3), spacing: HBSpacing.md) {
                ForEach(Array(goals.enumerated()), id: \.element.0) { index, goal in
                    let isSelected = store.responses.goals.contains(goal.0)
                    let color: Color = index % 2 == 0 ? .hbPrimary : .hbLavender

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                            if isSelected { store.responses.goals.remove(goal.0) }
                            else { _ = store.responses.goals.insert(goal.0) }
                        }
                    }) {
                        VStack(spacing: HBSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? color.opacity(0.12) : color.opacity(0.05))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Circle().stroke(isSelected ? color : color.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                                    )
                                Image(systemName: goal.1)
                                    .font(.system(size: 22))
                                    .foregroundColor(color)
                            }
                            .scaleEffect(isSelected ? 1.05 : 1)

                            Text(goal.0)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isSelected ? color : .hbTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 30)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.08 + Double(index) * 0.04), value: appeared)
                }
            }
            .padding(.horizontal, HBSpacing.lg)

            HStack(spacing: HBSpacing.xs) {
                Text("\(store.responses.goals.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.hbPrimary)
                    .contentTransition(.numericText())
                Text("selected").font(HBTypography.bodySmall).foregroundColor(.hbTextSecondary)
            }

            Spacer()
            HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                .padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - 8: Existing Systems — Toggles
private struct ExistingSystemsStep: View {
    let store: OnboardingStore
    @State private var appeared = false
    @State private var wifiPulse: CGFloat = 1

    let systems: [(String, String)] = [
        ("Smart thermostat", "thermometer.medium"), ("Security system", "lock.shield.fill"),
        ("Sprinkler system", "drop.fill"), ("Solar panels", "sun.max.fill"),
        ("Pool / spa", "figure.pool.swim"), ("Generator", "bolt.fill"),
        ("Water softener", "drop.triangle.fill"), ("Sump pump", "arrow.down.to.line.circle.fill"),
    ]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HBSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Color.hbSurface).frame(width: 200, height: 120).hbShadow(.sm)
                    VStack(spacing: HBSpacing.sm) {
                        HStack {
                            Circle().fill(Color.hbPrimary).frame(width: 6, height: 6)
                            Text("Smart Home").font(.system(size: 10, weight: .semibold)).foregroundColor(.hbTextPrimary)
                            Spacer()
                            Image(systemName: "wifi").font(.system(size: 10)).foregroundColor(.hbPrimary).scaleEffect(wifiPulse)
                        }.padding(.horizontal, 12)
                        HStack(spacing: 10) {
                            MiniGauge(icon: "thermometer.medium", value: "72°", color: .hbLavender, fill: 0.7)
                            MiniGauge(icon: "drop.fill", value: "45%", color: .hbPrimary, fill: 0.45)
                            MiniGauge(icon: "bolt.fill", value: "1.2k", color: .hbLavender, fill: 0.6)
                        }
                    }.frame(width: 200)
                }.scaleEffect(appeared ? 1 : 0.85).opacity(appeared ? 1 : 0).padding(.top, HBSpacing.md)

                Text("Any existing systems?").font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.hbTextPrimary).opacity(appeared ? 1 : 0)
                Text("Toggle what you have").font(HBTypography.bodySmall).foregroundColor(.hbTextSecondary)

                VStack(spacing: 1) {
                    ForEach(Array(systems.enumerated()), id: \.element.0) { i, sys in
                        let isOn = store.responses.existingSystems.contains(sys.0)
                        let color: Color = i % 2 == 0 ? .hbPrimary : .hbLavender
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isOn { store.responses.existingSystems.remove(sys.0) }
                                else { _ = store.responses.existingSystems.insert(sys.0) }
                            }
                        }) {
                            HStack(spacing: HBSpacing.md) {
                                Image(systemName: sys.1).font(.system(size: 17)).foregroundColor(color).frame(width: 22)
                                Text(sys.0).font(.system(size: 15)).foregroundColor(.hbTextPrimary)
                                Spacer()
                                Capsule().fill(isOn ? color : Color.hbBorder.opacity(0.35)).frame(width: 42, height: 24)
                                    .overlay(alignment: isOn ? .trailing : .leading) {
                                        Circle().fill(.white).frame(width: 20, height: 20).padding(2)
                                            .shadow(color: .black.opacity(0.08), radius: 1.5, y: 1)
                                    }
                            }.padding(.horizontal, HBSpacing.md).padding(.vertical, HBSpacing.sm + 3).background(Color.hbSurface)
                        }.buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .animation(HBAnimation.springGentle.delay(0.08 + Double(i) * 0.025), value: appeared)
                    }
                }.cornerRadius(HBRadii.card).padding(.horizontal, HBSpacing.lg).hbShadow(.sm)

                HBButton(title: "Continue") { store.nextStep() }.padding(.horizontal, HBSpacing.lg)
                HBTextButton(title: "Skip") { store.nextStep() }
                Spacer().frame(height: HBSpacing.lg)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { wifiPulse = 1.1 }
        }
    }
}

// MARK: - 9: Notifications
private struct NotificationStep: View {
    let store: OnboardingStore
    @State private var appeared = false
    @State private var bellSwing: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: HBSpacing.lg) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().stroke(Color.hbPrimary.opacity(appeared ? 0 : 0.1), lineWidth: 1.5)
                            .frame(width: appeared ? 160 + CGFloat(i) * 28 : 50)
                            .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(i) * 0.4), value: appeared)
                    }
                    ZStack {
                        Circle().fill(LinearGradient(colors: [.hbSurfaceMint, .hbPrimary.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 75)
                        Image(systemName: "bell.fill").font(.system(size: 34))
                            .foregroundStyle(LinearGradient(colors: [.hbPrimary, .hbPrimaryDark], startPoint: .top, endPoint: .bottom))
                            .rotationEffect(.degrees(bellSwing), anchor: .top)
                    }.scaleEffect(appeared ? 1 : 0.3)
                }.frame(height: 170).padding(.top, HBSpacing.sm)

                Text("When should we\nremind you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.hbTextPrimary).multilineTextAlignment(.center).lineSpacing(4).opacity(appeared ? 1 : 0)

                let prefs = OnboardingResponses.NotificationPreference.allCases
                let labels = ["☀️ Morning", "🌤️ Afternoon", "🌙 Evening", "📅 Weekends", "⏳ Later"]
                VStack(spacing: HBSpacing.sm) {
                    HStack(spacing: HBSpacing.sm) { ForEach(0..<3, id: \.self) { i in notifPill(prefs[i], labels[i], i) } }
                    HStack(spacing: HBSpacing.sm) { ForEach(3..<5, id: \.self) { i in notifPill(prefs[i], labels[i], i) } }
                }.padding(.horizontal, HBSpacing.lg)

                Spacer().frame(height: HBSpacing.md)
                HBButton(title: "Continue", isEnabled: store.canContinue) { store.nextStep() }
                    .padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.4).repeatCount(5, autoreverses: true).delay(0.4)) { bellSwing = 10 }
        }
    }
    @ViewBuilder private func notifPill(_ p: OnboardingResponses.NotificationPreference, _ label: String, _ i: Int) -> some View {
        let sel = store.responses.notificationPreference == p
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { store.responses.notificationPreference = p }
        }) {
            Text(label).font(.system(size: 14, weight: sel ? .semibold : .medium))
                .foregroundColor(sel ? .white : .hbPrimary).frame(maxWidth: .infinity)
                .padding(.vertical, HBSpacing.md).background(sel ? Color.hbPrimary : Color.hbPrimary.opacity(0.06))
                .cornerRadius(HBRadii.chip)
        }.buttonStyle(ScaleButtonStyle()).opacity(appeared ? 1 : 0)
        .animation(HBAnimation.springGentle.delay(0.15 + Double(i) * 0.04), value: appeared)
    }
}

// MARK: - 10: Personalized — Checklist
private struct PersonalizedStep: View {
    let store: OnboardingStore
    @State private var appeared = false
    @State private var checks: [Bool] = Array(repeating: false, count: 4)
    @State private var sealStamp = false

    let features: [(String, String)] = [
        ("Schedule customized", "calendar.badge.checkmark"),
        ("Smart reminders ready", "bell.badge.fill"),
        ("Category tracking on", "chart.bar.fill"),
        ("Contractor network", "person.2.fill"),
    ]
    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer()
            ZStack {
                Circle().stroke(AngularGradient(colors: [.hbPrimary, .hbLavender, .hbPrimary], center: .center), lineWidth: 3.5)
                    .frame(width: 108).rotationEffect(.degrees(appeared ? 360 : 0))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: appeared)
                Circle().fill(Color.hbSurfaceMint).frame(width: 88)
                Image(systemName: "checkmark.seal.fill").font(.system(size: 42))
                    .foregroundStyle(LinearGradient(colors: [.hbPrimary, .hbPrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .scaleEffect(sealStamp ? 1 : 0).rotationEffect(.degrees(sealStamp ? 0 : -45))
            }.scaleEffect(appeared ? 1 : 0.5).frame(height: 135)
            Text("You're all set!").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(.hbTextPrimary).opacity(appeared ? 1 : 0)
            VStack(alignment: .leading, spacing: HBSpacing.md) {
                ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                    let color: Color = i % 2 == 0 ? .hbPrimary : .hbLavender
                    HStack(spacing: HBSpacing.md) {
                        ZStack {
                            Circle().fill(checks[i] ? color : Color.hbBorder.opacity(0.3)).frame(width: 26)
                            if checks[i] { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white).transition(.scale) }
                        }
                        Text(f.0).font(HBTypography.body).foregroundColor(checks[i] ? .hbTextPrimary : .hbTextSecondary)
                        Spacer()
                        Image(systemName: f.1).font(.system(size: 15)).foregroundColor(checks[i] ? color : .hbBorder)
                    }
                }
            }.padding(.horizontal, HBSpacing.xl)
            Spacer()
            HBButton(title: "Continue") { store.nextStep() }.padding(.horizontal, HBSpacing.lg).padding(.bottom, HBSpacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { sealStamp = true }
            }
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(i) * 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { checks[i] = true }
                }
            }
        }
    }
}

// MARK: - 11: Loading Plan — Auto-advances to paywall
private struct LoadingPlanStep: View {
    let store: OnboardingStore
    @State private var progress: CGFloat = 0
    @State private var currentLabel = "Analyzing your home..."
    @State private var appeared = false

    private let steps = [
        (0.12, "Scanning your home profile..."),
        (0.25, "Analyzing maintenance history..."),
        (0.40, "Building maintenance schedule..."),
        (0.55, "Setting up smart reminders..."),
        (0.70, "Calibrating home health score..."),
        (0.88, "Personalizing insights..."),
        (1.0, "Your plan is ready!"),
    ]

    var body: some View {
        VStack(spacing: HBSpacing.xl) {
            Spacer()

            // Animated house assembling
            ZStack {
                Circle()
                    .stroke(Color.hbBorder.opacity(0.2), lineWidth: 4)
                    .frame(width: 120)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.hbPrimary, .hbLavender], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 120)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "house.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.hbPrimary)
                    .scaleEffect(appeared ? 1 : 0.5)
            }
            .frame(height: 140)

            VStack(spacing: HBSpacing.sm) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.hbPrimary)
                    .contentTransition(.numericText())

                Text(currentLabel)
                    .font(HBTypography.body)
                    .foregroundColor(.hbTextSecondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: currentLabel)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }

            for (i, step) in steps.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5 + 0.5) {
                    withAnimation(.easeOut(duration: 0.8)) { progress = step.0 }
                    currentLabel = step.1
                }
            }
            // Auto-advance to paywall
            DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                store.nextStep()
            }
        }
    }
}

// MARK: - 12: Paywall — StoreKit integrated
private struct PaywallStep: View {
    let store: OnboardingStore
    @Environment(SubscriptionManager.self) private var subManager
    @State private var appeared = false
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false

    enum Plan { case yearly, monthly }

    private let reviews = [
        ("Sarah M.", "Finally an app that makes home maintenance easy. Saved me $2,000 on preventable repairs!"),
        ("Mike R.", "The reminders alone are worth it. Never forget a filter change again."),
        ("Jennifer L.", "Love the contractor tracking. Everything in one place."),
    ]

    private var ctaTitle: String {
        if let product = selectedPlan == .yearly ? subManager.yearlyProduct : subManager.monthlyProduct {
            return "Continue — \(product.displayPrice)/\(selectedPlan == .yearly ? "yr" : "mo")"
        }
        return selectedPlan == .yearly ? "Continue — $24.99/yr" : "Continue — $4.99/mo"
    }

    private var yearlyPrice: String {
        subManager.yearlyProduct.map { "\($0.displayPrice)" } ?? "$24.99"
    }

    private var monthlyPrice: String {
        subManager.monthlyProduct.map { "\($0.displayPrice)" } ?? "$4.99"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { store.complete() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.hbTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.hbBorder.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, HBSpacing.lg).padding(.top, HBSpacing.sm)

            ScrollView(showsIndicators: false) {
                VStack(spacing: HBSpacing.lg) {
                    ZStack {
                        Circle().fill(Color.hbSurfaceMint).frame(width: 80)
                        Image(systemName: "crown.fill").font(.system(size: 32))
                            .foregroundStyle(LinearGradient(colors: [.hbPrimary, .hbLavender], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .scaleEffect(appeared ? 1 : 0.5).opacity(appeared ? 1 : 0)

                    VStack(spacing: HBSpacing.sm) {
                        Text("Unlock your full\nhome potential")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.hbTextPrimary).multilineTextAlignment(.center).lineSpacing(4)
                        Text("Home score: 78/100 — see what's driving it")
                            .font(.system(size: 14, weight: .medium)).foregroundColor(.hbPrimary)
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 15)

                    VStack(alignment: .leading, spacing: HBSpacing.md) {
                        featureRow("AI-powered maintenance predictions")
                        featureRow("Unlimited logging & full history")
                        featureRow("Smart contractor comparisons")
                        featureRow("Home value tracking & reports")
                    }
                    .padding(.horizontal, HBSpacing.xl)
                    .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)

                    // Review carousel
                    TabView {
                        ForEach(reviews, id: \.0) { review in
                            VStack(spacing: HBSpacing.sm) {
                                HStack(spacing: 2) {
                                    ForEach(0..<5, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.hbAmber)
                                    }
                                }
                                Text("\"\(review.1)\"")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.hbTextPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                Text("— \(review.0)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.hbTextSecondary)
                            }
                            .padding(HBSpacing.md)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 120)
                    .padding(.horizontal, HBSpacing.lg)

                    Spacer().frame(height: HBSpacing.sm)

                    HStack(spacing: HBSpacing.md) {
                        planCard(plan: .yearly, title: "Yearly", price: yearlyPrice, subtitle: "per year", badge: "MOST POPULAR")
                        planCard(plan: .monthly, title: "Monthly", price: monthlyPrice, subtitle: "per month", badge: nil)
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

                    HBButton(title: isPurchasing ? "Processing..." : ctaTitle, isEnabled: !isPurchasing) {
                        Task { await purchase() }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)

                    VStack(spacing: HBSpacing.xs) {
                        if subManager.yearlyProduct?.subscription?.introductoryOffer != nil {
                            Text("7-day free trial · Cancel anytime")
                                .font(.system(size: 12, weight: .medium)).foregroundColor(.hbPrimary)
                        }
                        Text("Auto-renews. Cancel anytime in Settings.")
                            .font(.system(size: 12)).foregroundColor(.hbTextSecondary)
                        HStack(spacing: HBSpacing.md) {
                            Button("Restore") { Task { await subManager.restore(); if subManager.isPremium { store.complete() } } }
                                .font(.system(size: 12, weight: .medium)).foregroundColor(.hbTextSecondary)
                            Link("Terms", destination: URL(string: "https://keshavkrishnan08.github.io/Dwello/#terms")!)
                                .font(.system(size: 12, weight: .medium)).foregroundColor(.hbTextSecondary)
                            Link("Privacy", destination: URL(string: "https://keshavkrishnan08.github.io/Dwello/#privacy")!)
                                .font(.system(size: 12, weight: .medium)).foregroundColor(.hbTextSecondary)
                        }
                    }.padding(.top, HBSpacing.xs)

                    Spacer().frame(height: HBSpacing.lg)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        }
    }

    private func purchase() async {
        let product: Product?
        switch selectedPlan {
        case .yearly: product = subManager.yearlyProduct
        case .monthly: product = subManager.monthlyProduct
        }
        guard let product = product else { store.complete(); return }

        isPurchasing = true
        defer { isPurchasing = false }

        if let success = try? await subManager.purchase(product), success {
            store.complete()
        }
    }

    @ViewBuilder
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: HBSpacing.sm) {
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.hbPrimary)
            Text(text).font(.system(size: 15)).foregroundColor(.hbTextPrimary)
        }
    }

    @ViewBuilder
    private func planCard(plan: Plan, title: String, price: String, subtitle: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedPlan = plan }
        }) {
            VStack(spacing: HBSpacing.sm) {
                if let badge = badge {
                    Text(badge.uppercased()).font(.system(size: 10, weight: .bold)).tracking(0.5)
                        .foregroundColor(isSelected ? .white : .hbPrimary)
                } else { Spacer().frame(height: 14) }
                Text(title).font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .hbTextPrimary)
                Text(price).font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .hbTextPrimary)
                Text(subtitle).font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .hbTextSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, HBSpacing.lg)
            .background(
                isSelected
                ? AnyShapeStyle(LinearGradient(colors: [.hbPrimary, .hbPrimaryDark], startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(Color.hbSurface)
            )
            .cornerRadius(HBRadii.card)
            .overlay(RoundedRectangle(cornerRadius: HBRadii.card).stroke(isSelected ? .clear : Color.hbBorder, lineWidth: 1.5))
            .hbShadow(isSelected ? .cta : .sm)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Helpers

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct HalfArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: rect.width / 2,
                  startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return p
    }
}

private struct WindowPane: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2).fill(Color.hbPrimary.opacity(0.12)).frame(width: 14, height: 14)
    }
}

private struct MiniGauge: View {
    let icon: String; let value: String; let color: Color; let fill: Double
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().trim(from: 0, to: 0.75).stroke(color.opacity(0.1), lineWidth: 2).frame(width: 32).rotationEffect(.degrees(135))
                Circle().trim(from: 0, to: fill * 0.75).stroke(color, lineWidth: 2).frame(width: 32).rotationEffect(.degrees(135))
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            }
            Text(value).font(.system(size: 8, weight: .medium)).foregroundColor(.hbTextSecondary)
        }
    }
}
