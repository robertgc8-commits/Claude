import SwiftUI
import SwiftData

struct ProgressView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm: ProgressViewModel

    init() {
        _vm = StateObject(wrappedValue: ProgressViewModel(
            context: ModelContext(try! ModelContainer(for: Workout.self)),
            userId: ""
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if vm.personalRecords.isEmpty && vm.exerciseNames.isEmpty
                        && vm.bodyWeightEntries.isEmpty {
                        emptyState
                    } else {
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Current weight card
                        if let latest = vm.latestBodyWeight {
                            VStack(spacing: 4) {
                                Text(String(format: "%.1f", latest.weightKg))
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.ffText)
                                Text("kg now")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.ffSubtext)
                                if let trend = vm.bodyWeightTrend {
                                    Text(trend >= 0 ? "+\(String(format: "%.1f", trend))" : String(format: "%.1f", trend))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(trend < 0 ? Color.ffGreen : Color.ffRed)
                                }
                            }
                            .frame(width: 90)
                            .padding(.vertical, 14)
                            .ffCard()
                        }

                        // Mini chart (last 10 entries)
                        let recent = Array(vm.bodyWeightEntries.prefix(10).reversed())
                        if recent.count >= 2 {
                            let weights = recent.map { $0.weightKg }
                            let minW = weights.min() ?? 0
                            let maxW = weights.max() ?? 1
                            let range = max(maxW - minW, 1)

                            HStack(alignment: .bottom, spacing: 5) {
                                ForEach(recent) { entry in
                                    let h = max(8, CGFloat((entry.weightKg - minW) / range) * 50 + 8)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(entry.id == recent.last?.id ? Color.ffAccent : Color.ffAccent.opacity(0.4))
                                        .frame(width: 12, height: h)
                                }
                            }
                            .frame(height: 60)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .ffCard()
                        }

                        // Recent entries
                        ForEach(vm.bodyWeightEntries.prefix(5)) { entry in
                            VStack(spacing: 4) {
                                Text(String(format: "%.1f", entry.weightKg))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.ffText)
                                Text("kg")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.ffSubtext)
                                Text(entry.loggedAt.relativeDisplay())
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.ffSubtext)
                            }
                            .frame(width: 64)
                            .padding(.vertical, 12)
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

            if let prs = vm.prsByExercise[name], !prs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(prs.sorted { $0.achievedAt > $1.achievedAt }) { pr in
                        VStack(spacing: 4) {
                            PRBadge(pr: pr).padding(.horizontal, 16)
                            if let e1rm = vm.estimated1RM(for: pr), pr.recordType == .heaviestWeight {
                                HStack {
                                    Spacer()
                                    Text("Est. 1RM: \(String(format: "%.1f", e1rm)) kg")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.ffGold)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }

            if let trend = vm.volumeTrend {
                volumeTrendCard(trend).padding(.horizontal, 16)
            }

            if !vm.historicalSets.isEmpty {
                weightHistoryCard.padding(.horizontal, 16)
            }

            if let summary = vm.lastSessionSummary {
                lastSessionCard(summary).padding(.horizontal, 16)
            }
        }
    }

    private func volumeTrendCard(_ trend: ProgressOverloadEngine.VolumeTrend) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Volume Trend").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
                Spacer()
                trendLabel(trend.trend)
            }
            if !trend.weeklyVolumes.isEmpty {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(trend.weeklyVolumes, id: \.weekStart) { week in
                        let maxVol = trend.weeklyVolumes.map { $0.volume }.max() ?? 1
                        let height = max(4, CGFloat(week.volume / maxVol) * 60)
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.ffAccent).frame(height: height)
                            Text(week.weekStart.weekdayShort).font(.system(size: 9)).foregroundStyle(Color.ffSubtext)
                        }
                    }
                }
                .frame(maxWidth: .infinity).padding(.top, 4)
            }
            Text("4-week avg: \(trend.fourWeekAverage.volumeDisplay()) kg")
                .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
        }
        .padding(14).ffCard()
    }

    private func trendLabel(_ trend: ProgressOverloadEngine.VolumeTrend.TrendDirection) -> some View {
        let (text, color): (String, Color) = {
            switch trend {
            case .improving:   return ("Improving ↗", .ffGreen)
            case .declining:   return ("Declining ↘", .ffRed)
            case .stable:      return ("Stable →",    .ffSubtext)
            case .insufficient: return ("More data needed", .ffSubtext)
            }
        }()
        return Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
    }

    private var weightHistoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weight History").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
            let recent = Array(vm.historicalSets.suffix(12))
            let maxW = recent.map { $0.weight }.max() ?? 1
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(recent) { set in
                    let height = max(4, CGFloat(set.weight / maxW) * 60)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(set.weight == maxW ? Color.ffGold : Color.ffAccent.opacity(0.6))
                        .frame(height: height)
                }
            }
            .frame(maxWidth: .infinity)
            HStack {
                Text("Max: \(String(format: "%.1f", maxW))kg")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.ffGold)
                Spacer()
                Text("Last \(recent.count) sets")
                    .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            }
        }
        .padding(14).ffCard()
    }

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

    // MARK: - All PRs

    private var allPRsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Records").ffSectionHeader().padding(.horizontal, 16)
            ForEach(vm.personalRecords) { pr in
                PRBadge(pr: pr).padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar")
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
