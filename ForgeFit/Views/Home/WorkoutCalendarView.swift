import SwiftUI

struct WorkoutCalendarView: View {
    /// calendarWorkouts: normalized day (startOfDay) → workout count
    let calendarWorkouts: [Date: Int]

    @State private var displayMonth: Date = {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        return cal.date(from: comps) ?? now
    }()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month navigation header
            HStack {
                Button {
                    navigateMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ffSubtext)
                        .frame(width: 32, height: 32)
                        .background(Color.ffSurface2)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ffText)

                Spacer()

                Button {
                    navigateMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ffSubtext)
                        .frame(width: 32, height: 32)
                        .background(Color.ffSurface2)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Day-of-week header
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.ffSubtext)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarCells, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            workoutCount: calendarWorkouts[calendar.startOfDay(for: date)] ?? 0
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            // Month summary
            Text("\(monthWorkoutCount) workout\(monthWorkoutCount == 1 ? "" : "s") this month")
                .font(.system(size: 12))
                .foregroundStyle(Color.ffSubtext)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(14)
        .ffCard()
    }

    // MARK: - Helpers

    private var monthYearLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth)
    }

    /// Mon–Sun column headers
    private var weekdayLabels: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    /// Returns optional Dates for each cell in the grid; nil = padding cell
    private var calendarCells: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))
        else { return [] }

        // weekday of first day: calendar.component uses 1=Sun,2=Mon,...7=Sat
        // We want Mon=0 offset
        let rawWeekday = calendar.component(.weekday, from: firstDay)
        // Convert: Sun=1→6, Mon=2→0, Tue=3→1, ... Sat=7→5
        let leadingBlanks = (rawWeekday + 5) % 7

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                cells.append(date)
            }
        }
        return cells
    }

    private var monthWorkoutCount: Int {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        return calendarWorkouts.filter { entry in
            let entryComps = calendar.dateComponents([.year, .month], from: entry.key)
            return entryComps.year == comps.year && entryComps.month == comps.month
        }.values.reduce(0, +)
    }

    private func navigateMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newDate
        }
    }
}

// MARK: - Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let workoutCount: Int

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cellBackground)
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.ffAccent.opacity(0.6), lineWidth: 1.5)
                    }
                }

            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 11, weight: workoutCount > 0 ? .semibold : .regular))
                .foregroundStyle(textColor)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var isToday: Bool { calendar.isDateInToday(date) }

    private var isFuture: Bool { date > Date() }

    private var cellBackground: Color {
        if workoutCount == 0 {
            return Color.ffSurface
        }
        let opacity: Double = workoutCount >= 2 ? 1.0 : 0.6
        return Color.ffAccent.opacity(opacity)
    }

    private var textColor: Color {
        if workoutCount > 0 { return .white }
        if isFuture { return Color.ffSubtext.opacity(0.4) }
        return Color.ffSubtext
    }
}
