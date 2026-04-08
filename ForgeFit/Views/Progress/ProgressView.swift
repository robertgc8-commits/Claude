import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = ProgressViewModel()

    @State private var bodyWeightRange: BodyWeightRange = .threeMonths

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if vm.personalRecords.isEmpty && vm.exerciseNames.isEmpty
                        && vm.bodyWeightEntries.isEmpty && vm.calendarWorkouts.isEmpty {
                        emptyState
                    } else {
                        if vm.allTimeStats.totalWorkouts > 0 {
                            allTimeStatsSection
                        }
                        if !vm.calendarWorkouts.isEmpty {
                            heatmapSection
                        }
                        bodyWeightSection
                        muscleGroupSection
                        if !vm.exerciseNames.isEmpty { exerciseSelector }
                        if let exercise = vm.selectedExercise {
                            exerciseProgressSection(exercise)
                        }
                        if !vm.personalRecords.isEmpty { allPRsSection }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color.ffBackground)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
        .sheet(isPresented: $vm.showingBodyWeightInput) {
            bodyWeightInputSheet
        }
    }

    // MARK: - All-Time Stats

    private var allTimeStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Time")
                .ffSectionHeader()
                .padding(.horizontal, 16)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                statCell("\(vm.allTimeStats.totalWorkouts)", label: "Workouts")
                statCell("\(vm.allTimeStats.totalSets)", label: "Sets")
                statCell(vm.allTimeStats.totalVolume.volumeDisplay(), label: "Volume")
                statCell(vm.allTimeStats.timeDisplay, label: "Time")
                statCell("\(vm.allTimeStats.uniqueExercises)", label: "Exercises")
                statCell("\(vm.allTimeStats.prCount)", label: "Records")
            }
            .padding(.horizontal, 16)
        }
    }

    private func statCell(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ffText)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.ffSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .ffCard()
    }

    // MARK: - Activity Heatmap (26 weeks)

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity")
                .ffSectionHeader()
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                heatmapGrid
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }
        }
    }

    private var heatmapGrid: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Find the Monday 25 weeks before this week's Monday
        var thisWeekComps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        thisWeekComps.weekday = 2 // Monday
        let thisMonday = cal.date(from: thisWeekComps) ?? today
        let startDate = cal.date(byAdding: .weekOfYear, value: -25, to: thisMonday) ?? today

        return HStack(alignment: .top, spacing: 3) {
            ForEach(0..<26, id: \.self) { weekIdx in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { dayIdx in
                        let date = cal.date(byAdding: .day, value: weekIdx * 7 + dayIdx, to: startDate) ?? startDate
                        let count = vm.calendarWorkouts[date] ?? 0
                        let isFuture = date > today

                        RoundedRectangle(cornerRadius: 2)
                            .fill(isFuture ? Color.clear : heatmapColor(count: count))
                            .frame(width: 12, height: 12)
                            .overlay {
                                if cal.isDateInToday(date) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.ffAccent, lineWidth: 1)
                                }
                            }
                    }
                }
            }
        }
    }

    private func heatmapColor(count: Int) -> Color {
        switch count {
        case 0:  return Color.ffSurface
        case 1:  return Color.ffAccent.opacity(0.4)
        case 2:  return Color.ffAccent.opacity(0.7)
        default: return Color.ffAccent
        }
    }

    // MARK: - Body Weight

    private var bodyWeightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Body Weight")
                    .ffSectionHeader()
                Spacer()
                Button {
                    vm.showingBodyWeightInput = true
                } label: {
                    Label("Log", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.ffAccent)
                }
            }
            .padding(.horizontal, 16)

            if vm.bodyWeightEntries.isEmpty {
                Text("Tap + to log your weight")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ffSubtext)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 10) {
                    // Current + trend
                    if let latest = vm.latestBodyWeight {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", latest.weightKg))
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundStyle(Color.ffText)
                                    Text("kg")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.ffSubtext)
                                }
                                if let trend = vm.bodyWeightTrend {
                                    Text(trend >= 0 ? "+\(String(format: "%.1f", trend)) kg" : "\(String(format: "%.1f", trend)) kg")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(trend < 0 ? Color.ffGreen : Color.ffOrange)
                                }
                            }
                            Spacer()
                            // Range picker
                            HStack(spacing: 0) {
                                ForEach(BodyWeightRange.allCases, id: \.self) { range in
                                    Button(range.rawValue) {
                                        bodyWeightRange = range
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(bodyWeightRange == range ? .white : Color.ffSubtext)
                                    .padding(.horizontal, 8).padding(.vertical, 5)
                                    .background(bodyWeightRange == range ? Color.ffAccent : Color.clear)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(3)
                            .background(Color.ffSurface)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                    }

                    // Line chart
                    let chartEntries = filteredBodyWeightEntries
                    if chartEntries.count >= 2 {
                        bodyWeightChart(chartEntries)
                            .padding(.horizontal, 16)
                    }

                    // Recent entries (scrollable)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(vm.bodyWeightEntries.prefix(8)) { entry in
                                VStack(spacing: 4) {
                                    Text(String(format: "%.1f", entry.weightKg))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Color.ffText)
                                    Text("kg")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.ffSubtext)
                                    Text(entry.loggedAt.relativeDisplay())
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.ffSubtext)
                                }
                                .frame(width: 60)
                                .padding(.vertical, 10)
                                .ffCard()
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        vm.deleteBodyWeightEntry(entry)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private var filteredBodyWeightEntries: [BodyWeightEntry] {
        let entries = vm.bodyWeightEntries.sorted { $0.loggedAt < $1.loggedAt }
        guard let days = bodyWeightRange.days else { return entries }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.loggedAt >= cutoff }
    }

    private func bodyWeightChart(_ entries: [BodyWeightEntry]) -> some View {
        Chart(entries) { entry in
            LineMark(
                x: .value("Date", entry.loggedAt),
                y: .value("Weight", entry.weightKg)
            )
            .foregroundStyle(Color.ffAccent)
            .interpolationMethod(.catmullRom)
            AreaMark(
                x: .value("Date", entry.loggedAt),
                y: .value("Weight", entry.weightKg)
            )
            .foregroundStyle(Color.ffAccent.opacity(0.12))
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value("Date", entry.loggedAt),
                y: .value("Weight", entry.weightKg)
            )
            .foregroundStyle(Color.ffAccent)
            .symbolSize(24)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 140)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color.ffSubtext)
                AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.35))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .number.precision(.fractionLength(1)))
                    .foregroundStyle(Color.ffSubtext)
                AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.35))
            }
        }
        .padding(14)
        .ffCard()
    }

    private var bodyWeightInputSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Log Body Weight")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.ffText)
                    .padding(.top, 24)

                HStack(spacing: 8) {
                    TextField("0.0", text: $vm.bodyWeightInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ffAccent)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    Text("kg")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.ffSubtext)
                }
                .padding(.horizontal, 32)

                FFButton(title: "Save", style: .primary) {
                    vm.logBodyWeight()
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.ffBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { vm.showingBodyWeightInput = false }
                        .foregroundStyle(Color.ffSubtext)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Muscle Group Frequency

    @ViewBuilder
    private var muscleGroupSection: some View {
        if !vm.muscleGroupFrequency.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Muscle Groups")
                    .ffSectionHeader()
                    .padding(.horizontal, 16)

                let maxCount = vm.muscleGroupFrequency.first?.count ?? 1
                VStack(spacing: 6) {
                    ForEach(vm.muscleGroupFrequency.prefix(6), id: \.group) { item in
                        HStack(spacing: 10) {
                            Text(item.group.rawValue)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.ffSubtext)
                                .frame(width: 80, alignment: .leading)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.ffAccent.opacity(0.85))
                                    .frame(width: max(8, geo.size.width * CGFloat(item.count) / CGFloat(maxCount)))
                            }
                            .frame(height: 20)
                            Text("\(item.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.ffText)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Exercise Selector

    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Exercise")
                .ffSectionHeader()
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.exerciseNames, id: \.self) { name in
                        Button {
                            vm.selectExercise(name)
                        } label: {
                            Text(name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(vm.selectedExercise == name ? .white : Color.ffSubtext)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(vm.selectedExercise == name ? Color.ffAccent : Color.ffSurface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Exercise Progress

    @ViewBuilder
    private func exerciseProgressSection(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.ffText)
                .padding(.horizontal, 16)

            // Strength curve chart
            if vm.strengthCurve.count >= 2 {
                strengthCurveChart.padding(.horizontal, 16)
            }

            // Weekly volume chart
            weeklyVolumeChart.padding(.horizontal, 16)

            // Relative strength (conditional on body weight data)
            relativeStrengthChart
                .padding(.horizontal, 16)

            if let summary = vm.lastSessionSummary {
                lastSessionCard(summary).padding(.horizontal, 16)
            }

            if let prs = vm.prsByExercise[name], !prs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Records")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffSubtext)
                        .padding(.horizontal, 16)
                    ForEach(prs.sorted { $0.achievedAt > $1.achievedAt }) { pr in
                        PRBadge(pr: pr).padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    // MARK: - Strength Curve Chart

    private var strengthCurveChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated 1RM")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
                Text("Brzycki formula, sets of 1–12 reps")
                    .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
            }

            Chart(vm.strengthCurve, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("1RM (kg)", point.estimated1RM)
                )
                .foregroundStyle(Color.ffAccent)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("1RM (kg)", point.estimated1RM)
                )
                .foregroundStyle(Color.ffAccent.opacity(0.12))
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("1RM (kg)", point.estimated1RM)
                )
                .foregroundStyle(Color.ffAccent)
                .symbolSize(24)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(Color.ffSubtext)
                    AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.3))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .number.precision(.fractionLength(1)))
                        .foregroundStyle(Color.ffSubtext)
                    AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.3))
                }
            }
        }
        .padding(14)
        .ffCard()
    }

    // MARK: - Weekly Volume Chart

    private var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Volume")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)

            if let trend = vm.volumeTrend, !trend.weeklyVolumes.isEmpty {
                Chart(trend.weeklyVolumes, id: \.weekStart) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Volume (kg)", week.volume)
                    )
                    .foregroundStyle(Color.ffAccent.opacity(0.8))
                    .cornerRadius(4)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.ffSubtext)
                        AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.ffSubtext)
                        AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.3))
                    }
                }

                HStack {
                    trendLabel(trend.trend)
                    Spacer()
                    Text("4-wk avg: \(trend.fourWeekAverage.volumeDisplay()) kg")
                        .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                }
            } else {
                Text("Log more workouts to see volume trends")
                    .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                    .frame(height: 60, alignment: .center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .ffCard()
    }

    // MARK: - Relative Strength Chart

    @ViewBuilder
    private var relativeStrengthChart: some View {
        if vm.relativeStrengthData.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Relative Strength")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
                    Text("1RM ÷ body weight")
                        .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
                }

                Chart(vm.relativeStrengthData, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Ratio", point.ratio)
                    )
                    .foregroundStyle(Color.ffPurple)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Ratio", point.ratio)
                    )
                    .foregroundStyle(Color.ffPurple.opacity(0.12))
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Ratio", point.ratio)
                    )
                    .foregroundStyle(Color.ffPurple)
                    .symbolSize(24)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.ffSubtext)
                        AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(Color.ffSubtext)
                        AxisGridLine().foregroundStyle(Color.ffBorder.opacity(0.3))
                    }
                }
            }
            .padding(14)
            .ffCard()
        }
    }

    // MARK: - Last Session Card

    private func lastSessionCard(_ summary: ProgressOverloadEngine.LastSessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Session").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
                Spacer()
                Text(summary.workoutDate.relativeDisplay()).font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            }
            ForEach(summary.sets) { set in
                HStack {
                    Text("Set \(set.setNumber)").font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                    Spacer()
                    Text("\(String(format: "%.1f", set.weight))kg × \(set.reps)")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.ffText)
                }
            }
        }
        .padding(14).ffCard()
    }

    private func trendLabel(_ trend: ProgressOverloadEngine.VolumeTrend.TrendDirection) -> some View {
        let (text, color): (String, Color) = {
            switch trend {
            case .improving:    return ("Improving ↗", .ffGreen)
            case .declining:    return ("Declining ↘", .ffRed)
            case .stable:       return ("Stable →",    .ffSubtext)
            case .insufficient: return ("More data needed", .ffSubtext)
            }
        }()
        return Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
    }

    // MARK: - All PRs

    private var allPRsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Records").ffSectionHeader().padding(.horizontal, 16)
            ForEach(vm.personalRecords) { pr in
                PRBadge(pr: pr).padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52)).foregroundStyle(Color.ffBorder)
            Text("No data yet")
                .font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.ffSubtext)
            Text("Complete workouts to see your progress here")
                .font(.system(size: 14)).foregroundStyle(Color.ffSubtext.opacity(0.7))
                .multilineTextAlignment(.center)
            Button {
                vm.showingBodyWeightInput = true
            } label: {
                Label("Log Body Weight", systemImage: "scalemass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.ffAccent)
            }
            Spacer()
        }
        .padding(.horizontal, 32).frame(maxWidth: .infinity)
    }
}

// MARK: - Body Weight Range

private enum BodyWeightRange: String, CaseIterable {
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case sixMonths   = "6M"
    case oneYear     = "1Y"
    case all         = "All"

    var days: Int? {
        switch self {
        case .oneMonth:    return 30
        case .threeMonths: return 90
        case .sixMonths:   return 180
        case .oneYear:     return 365
        case .all:         return nil
        }
    }
}
