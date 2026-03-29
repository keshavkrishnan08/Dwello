import SwiftUI

struct TimelineTabView: View {
    @Environment(AppStore.self) private var appStore

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var appeared = false

    private var calendar: Calendar { Calendar.current }

    private var logsForSelectedDate: [LogEntry] {
        let selKey = dayKey(selectedDate)
        return appStore.logs.filter { dayKey($0.date) == selKey }
            .sorted { $0.date > $1.date }
    }

    private var remindersForSelectedDate: [Reminder] {
        let selKey = dayKey(selectedDate)
        return appStore.reminders.filter { !$0.isCompleted && dayKey($0.dueDate) == selKey }
    }

    private func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private var daysWithLogs: Set<String> {
        Set(appStore.logs.map { dayKey($0.date) })
    }

    private var daysWithReminders: Set<String> {
        Set(appStore.reminders.filter { !$0.isCompleted }.map { dayKey($0.dueDate) })
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                VStack(spacing: 0) {
                    // Month navigation
                    HStack {
                        Button(action: { changeMonth(-1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.hbTextSecondary)
                                .frame(width: 36, height: 36)
                        }

                        Spacer()

                        Text(monthTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.hbTextPrimary)

                        Spacer()

                        Button(action: { changeMonth(1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.hbTextSecondary)
                                .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.top, HBSpacing.sm)

                    // Weekday headers
                    HStack(spacing: 0) {
                        ForEach(Array(["S","M","T","W","T","F","S"].enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.hbTextSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, HBSpacing.md)
                    .padding(.top, HBSpacing.md)
                    .padding(.bottom, HBSpacing.xs)

                    // Calendar grid
                    let days = daysInMonth()
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                        ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                            if let day = day {
                                let isToday = calendar.isDateInToday(day)
                                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                                let dk = dayKey(day)
                                let hasLog = daysWithLogs.contains(dk)
                                let hasReminder = daysWithReminders.contains(dk)
                                let logCount = appStore.logs.filter { dayKey($0.date) == dk }.count

                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        selectedDate = day
                                    }
                                }) {
                                    VStack(spacing: 2) {
                                        Text("\(calendar.component(.day, from: day))")
                                            .font(.system(size: 15, weight: isSelected ? .bold : isToday ? .semibold : .regular))
                                            .foregroundColor(
                                                isSelected ? .white :
                                                isToday ? .hbPrimary :
                                                .hbTextPrimary
                                            )

                                        // Activity dots
                                        if hasLog || hasReminder {
                                            HStack(spacing: 2) {
                                                if hasLog {
                                                    ForEach(0..<min(logCount, 2), id: \.self) { _ in
                                                        Circle()
                                                            .fill(isSelected ? Color.white.opacity(0.8) : Color.hbPrimary)
                                                            .frame(width: 4, height: 4)
                                                    }
                                                }
                                                if hasReminder {
                                                    Circle()
                                                        .fill(isSelected ? Color.white.opacity(0.8) : Color.hbLavender)
                                                        .frame(width: 4, height: 4)
                                                }
                                            }
                                        } else {
                                            Spacer().frame(height: 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        isSelected ? Color.hbPrimary :
                                        isToday ? Color.hbPrimary.opacity(0.06) :
                                        Color.clear
                                    )
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Color.clear.frame(height: 44)
                            }
                        }
                    }
                    .padding(.horizontal, HBSpacing.md)

                    Divider().padding(.vertical, HBSpacing.sm).padding(.horizontal, HBSpacing.lg)

                    // Selected day header
                    VStack(alignment: .leading, spacing: HBSpacing.sm) {
                        HStack {
                            Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.hbTextPrimary)
                            Spacer()
                            let total = logsForSelectedDate.count + remindersForSelectedDate.count
                            if total > 0 {
                                Text("\(total) item\(total == 1 ? "" : "s")")
                                    .font(.system(size: 13))
                                    .foregroundColor(.hbTextSecondary)
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)

                        // Show upcoming reminders summary if nothing selected today
                        if logsForSelectedDate.isEmpty && remindersForSelectedDate.isEmpty {
                            let upcoming = appStore.upcomingReminders.prefix(3)
                            if !upcoming.isEmpty {
                                VStack(alignment: .leading, spacing: HBSpacing.xs) {
                                    Text("UPCOMING CHECK-INS")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.hbTextSecondary)
                                        .tracking(0.5)
                                    ForEach(Array(upcoming)) { r in
                                        HStack(spacing: HBSpacing.sm) {
                                            Circle()
                                                .fill(r.category.color)
                                                .frame(width: 6, height: 6)
                                            Text(r.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.hbTextPrimary)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(r.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                                                .font(.system(size: 12))
                                                .foregroundColor(r.isOverdue ? .hbDanger : .hbTextSecondary)
                                        }
                                    }
                                }
                                .padding(HBSpacing.md)
                                .background(Color.hbSurface)
                                .cornerRadius(12)
                                .padding(.horizontal, HBSpacing.lg)
                            }
                        }
                    }

                    if logsForSelectedDate.isEmpty && remindersForSelectedDate.isEmpty {
                        VStack(spacing: HBSpacing.sm) {
                            Spacer()
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 28))
                                .foregroundColor(.hbBorder)
                            Text("Nothing scheduled")
                                .font(.system(size: 14))
                                .foregroundColor(.hbTextSecondary)
                            Spacer()
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: HBSpacing.sm) {
                                // Upcoming checkups / reminders
                                ForEach(remindersForSelectedDate) { reminder in
                                    HStack(spacing: HBSpacing.md) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.hbLavender)
                                            .frame(width: 4, height: 40)
                                        Image(systemName: "bell.badge.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.hbLavender)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reminder.title)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.hbTextPrimary)
                                                .lineLimit(1)
                                            Text(reminder.isOverdue ? "Overdue" : "Upcoming")
                                                .font(.system(size: 12))
                                                .foregroundColor(reminder.isOverdue ? .hbDanger : .hbLavender)
                                        }
                                        Spacer()
                                        Text(reminder.category.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.hbTextSecondary)
                                    }
                                    .padding(.horizontal, HBSpacing.md)
                                    .padding(.vertical, HBSpacing.sm + 2)
                                    .background(Color.hbLavender.opacity(0.04))
                                    .cornerRadius(12)
                                }

                                // Past logs
                                ForEach(logsForSelectedDate) { entry in
                                    NavigationLink {
                                        LogDetailView(entry: entry)
                                    } label: {
                                        CalendarLogRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, HBSpacing.lg)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func changeMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekdayOffset = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekdayOffset)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        // Pad to fill last row
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

struct CalendarLogRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(spacing: HBSpacing.md) {
            RoundedRectangle(cornerRadius: 3)
                .fill(entry.category.color)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.hbTextPrimary)
                    .lineLimit(1)
                Text(entry.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 12))
                    .foregroundColor(.hbTextSecondary)
            }

            Spacer()

            if let cost = entry.cost, cost > 0 {
                Text("$\(Int(cost))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.hbTextPrimary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.hbBorder)
        }
        .padding(.horizontal, HBSpacing.md)
        .padding(.vertical, HBSpacing.sm + 2)
        .background(Color.hbSurface)
        .cornerRadius(12)
    }
}
