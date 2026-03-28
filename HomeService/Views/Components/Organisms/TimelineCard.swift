import SwiftUI

struct TimelineCard: View {
    let entry: LogEntry
    var onTap: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: HBSpacing.md) {
                // Category color dot
                Circle()
                    .fill(entry.category.color)
                    .frame(width: 10, height: 10)

                // Category icon
                ZStack {
                    Circle()
                        .fill(entry.category.color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: entry.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(entry.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(HBTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.hbTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: HBSpacing.sm) {
                        Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(HBTypography.caption)
                            .foregroundColor(.hbTextSecondary)

                        if let cost = entry.cost, cost > 0 {
                            Text("•")
                                .foregroundColor(.hbTextSecondary)
                            Text("$\(Int(cost))")
                                .font(HBTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.hbTextPrimary)
                        }
                    }
                }

                Spacer()

                if !entry.photoURLs.isEmpty {
                    Image(systemName: "photo")
                        .font(.system(size: 14))
                        .foregroundColor(.hbTextSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.hbBorder)
            }
            .padding(HBSpacing.md)
            .background(Color.hbSurface)
            .cornerRadius(HBRadii.card)
            .hbShadow(.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.category.rawValue): \(entry.title), \(entry.date.formatted(.dateTime.month(.abbreviated).day()))\(entry.cost.map { ", $\(Int($0))" } ?? "")")
        .accessibilityAddTraits(.isButton)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(HBAnimation.springGentle) {
                appeared = true
            }
        }
    }
}

struct TimelineSection: View {
    let title: String
    let entries: [LogEntry]
    var onEntryTap: ((LogEntry) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            Text(title)
                .font(HBTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.hbTextSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, HBSpacing.xs)

            VStack(spacing: HBSpacing.sm) {
                ForEach(entries) { entry in
                    TimelineCard(entry: entry) {
                        onEntryTap?(entry)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        TimelineCard(entry: .sample)
        TimelineCard(entry: LogEntry.samples[1])
    }
    .padding()
}
