import SwiftUI

struct HBProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 3) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    if index < currentStep {
                        // Active segment - solid
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.hbPrimary)
                            .frame(height: 3)
                    } else {
                        // Inactive segment - dashed
                        DashedSegment()
                            .stroke(Color.hbBorder, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                            .frame(height: 3)
                    }
                }
            }

            Spacer()

            Text("\(currentStep)/\(totalSteps)")
                .font(HBTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.hbTextSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, HBSpacing.lg)
    }
}

struct DashedSegment: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

struct HBCircularProgress: View {
    let progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 140
    var color: Color = .hbPrimary
    var showLabel: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.hbBorder.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: animatedProgress)

            if showLabel {
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))")
                        .font(HBTypography.statNumber)
                        .foregroundColor(.hbTextPrimary)
                    Text("score")
                        .font(HBTypography.caption)
                        .foregroundColor(.hbTextSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score \(Int(progress * 100)) out of 100")
        .accessibilityValue("\(Int(progress * 100)) percent")
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        HBProgressBar(currentStep: 5, totalSteps: 13)
        HBCircularProgress(progress: 0.82, color: .hbSuccess)
    }
}
