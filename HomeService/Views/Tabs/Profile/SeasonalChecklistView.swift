import SwiftUI

struct SeasonalChecklistView: View {
    @State private var appeared = false
    @State private var selectedSeason: Season = .current

    enum Season: String, CaseIterable {
        case spring = "Spring"
        case summer = "Summer"
        case fall = "Fall"
        case winter = "Winter"

        static var current: Season {
            let month = Calendar.current.component(.month, from: Date())
            switch month {
            case 3...5: return .spring
            case 6...8: return .summer
            case 9...11: return .fall
            default: return .winter
            }
        }

        var icon: String {
            switch self {
            case .spring: return "leaf.fill"
            case .summer: return "sun.max.fill"
            case .fall: return "wind"
            case .winter: return "snowflake"
            }
        }

        var color: Color {
            switch self {
            case .spring: return .hbExterior
            case .summer: return .hbElectrical
            case .fall: return .hbAppliance
            case .winter: return .hbPlumbing
            }
        }

        var tasks: [ChecklistTask] {
            switch self {
            case .spring:
                return [
                    .init(title: "Inspect roof for winter damage", category: .structural),
                    .init(title: "Clean gutters and downspouts", category: .exterior),
                    .init(title: "Service AC unit", category: .hvac),
                    .init(title: "Check outdoor faucets for freeze damage", category: .plumbing),
                    .init(title: "Test smoke and CO detectors", category: .electrical),
                    .init(title: "Pressure wash siding and deck", category: .exterior),
                    .init(title: "Inspect foundation for cracks", category: .structural),
                    .init(title: "Service lawn mower", category: .appliance),
                ]
            case .summer:
                return [
                    .init(title: "Replace AC filters monthly", category: .hvac),
                    .init(title: "Check irrigation system", category: .exterior),
                    .init(title: "Inspect and clean dryer vent", category: .appliance),
                    .init(title: "Touch up exterior paint", category: .exterior),
                    .init(title: "Clean refrigerator coils", category: .appliance),
                    .init(title: "Check caulking around windows", category: .structural),
                ]
            case .fall:
                return [
                    .init(title: "Service furnace/heating system", category: .hvac),
                    .init(title: "Clean gutters (leaves)", category: .exterior),
                    .init(title: "Seal gaps and weather-strip doors", category: .structural),
                    .init(title: "Drain outdoor faucets", category: .plumbing),
                    .init(title: "Check insulation in attic", category: .structural),
                    .init(title: "Test backup generator", category: .electrical),
                    .init(title: "Stock winter supplies (salt, shovels)", category: .exterior),
                ]
            case .winter:
                return [
                    .init(title: "Check for ice dams on roof", category: .structural),
                    .init(title: "Monitor pipes for freezing", category: .plumbing),
                    .init(title: "Replace furnace filter", category: .hvac),
                    .init(title: "Test smoke detectors (new batteries)", category: .electrical),
                    .init(title: "Check water heater temperature", category: .plumbing),
                    .init(title: "Inspect fireplace and chimney", category: .structural),
                ]
            }
        }
    }

    struct ChecklistTask: Identifiable {
        let id = UUID()
        let title: String
        let category: HomeCategory
        var isCompleted: Bool = false
    }

    @State private var tasks: [ChecklistTask] = Season.current.tasks

    var completedCount: Int { tasks.filter(\.isCompleted).count }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Season picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HBSpacing.sm) {
                        ForEach(Season.allCases, id: \.self) { season in
                            Button(action: {
                                withAnimation(HBAnimation.fast) {
                                    selectedSeason = season
                                    tasks = season.tasks
                                }
                            }) {
                                HStack(spacing: HBSpacing.xs) {
                                    Image(systemName: season.icon)
                                        .font(.system(size: 14))
                                    Text(season.rawValue)
                                        .font(HBTypography.chip)
                                }
                                .foregroundColor(selectedSeason == season ? .white : season.color)
                                .padding(.horizontal, HBSpacing.md)
                                .padding(.vertical, HBSpacing.sm)
                                .background(selectedSeason == season ? season.color : season.color.opacity(0.1))
                                .cornerRadius(HBRadii.chip)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.vertical, HBSpacing.sm)
                }

                // Progress
                VStack(spacing: HBSpacing.xs) {
                    Text("\(completedCount)/\(tasks.count) completed")
                        .font(HBTypography.bodySmall)
                        .foregroundColor(.hbTextSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.hbBorder.opacity(0.3))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedSeason.color)
                                .frame(width: tasks.isEmpty ? 0 : geo.size.width * CGFloat(completedCount) / CGFloat(max(tasks.count, 1)))
                                .animation(.easeOut(duration: 0.3), value: completedCount)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, HBSpacing.lg)
                .padding(.bottom, HBSpacing.sm)

                // Tasks
                ScrollView(showsIndicators: false) {
                    VStack(spacing: HBSpacing.sm) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            ChecklistRow(task: task, seasonColor: selectedSeason.color) {
                                withAnimation(HBAnimation.springInteractive) {
                                    tasks[index].isCompleted.toggle()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Seasonal Checklist")
    }
}

struct ChecklistRow: View {
    let task: SeasonalChecklistView.ChecklistTask
    let seasonColor: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: HBSpacing.md) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? seasonColor : .hbBorder)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(HBTypography.body)
                        .foregroundColor(task.isCompleted ? .hbTextSecondary : .hbTextPrimary)
                        .strikethrough(task.isCompleted)

                    HStack(spacing: HBSpacing.xs) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 10))
                        Text(task.category.rawValue)
                            .font(HBTypography.caption)
                    }
                    .foregroundColor(.hbTextSecondary)
                }

                Spacer()
            }
            .padding(HBSpacing.md)
            .background(Color.hbSurface)
            .cornerRadius(HBRadii.card)
            .hbShadow(.sm)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
