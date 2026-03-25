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
                    if vm.personalRecords.isEmpty && vm.exerciseNames.isEmpty {
                        emptyState
                    } else {
                        // Exercise selector
                        exerciseSelector

                        if let exercise = vm.selectedExercise {
                            exerciseProgressSection(exercise)
                        }

                        // All PRs
                        if !vm.personalRecords.isEmpty {
                            allPRsSection
                        }
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
    }

    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise")
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
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
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

    @ViewBuilder
    private func exerciseProgressSection(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.ffText)
                .padding(.horizontal, 16)

            // PRs for this exercise
            if let prs = vm.prsByExercise[name], !prs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(prs.sorted { $0.achievedAt > $1.achievedAt }) { pr in
                        PRBadge(pr: pr)
                            .padding(.horizontal, 16)
                    }
                }
            }

            // Volume trend
            if let trend = vm.volumeTrend {
                volumeTrendCard(trend)
                    .padding(.horizontal, 16)
            }

            // Set history chart
            if !vm.historicalSets.isEmpty {
                weightHistoryCard
                    .padding(.horizontal, 16)
            }

            // Last session summary
            if let summary = vm.lastSessionSummary {
                lastSessionCard(summary)
                    .padding(.horizontal, 16)
            }
        }
    }

    private func volumeTrendCard(_ trend: ProgressOverloadEngine.VolumeTrend) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Volume Trend")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ffText)
                Spacer()
                trendLabel(trend.trend)
            }

            // Simple bar chart
            if !trend.weeklyVolumes.isEmpty {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(trend.weeklyVolumes, id: \.weekStart) { week in
                        let maxVol = trend.weeklyVolumes.map { $0.volume }.max() ?? 1
                        let height = max(4, CGFloat(week.volume / maxVol) * 60)
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.ffAccent)
                                .frame(height: height)
                            Text(week.weekStart.weekdayShort)
                                .font(.system(size: 9))
                                .foregroundStyle(Color.ffSubtext)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }

            Text("4-week avg: \(trend.fourWeekAverage.volumeDisplay()) kg")
                .font(.system(size: 12))
                .foregroundStyle(Color.ffSubtext)
        }
        .padding(14)
        .ffCard()
    }

    private func trendLabel(_ trend: ProgressOverloadEngine.VolumeTrend.TrendDirection) -> some View {
        let (text, color): (String, Color) = {
            switch trend {
            case .improving: return ("Improving ↗", .ffGreen)
            case .declining: return ("Declining ↘", .ffRed)
            case .stable:    return ("Stable →", .ffSubtext)
            case .insufficient: return ("More data needed", .ffSubtext)
            }
        }()
        return Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
    }

    private var weightHistoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weight History")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.ffText)

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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.ffGold)
                Spacer()
                Text("Last \(recent.count) sets")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
        }
        .padding(14)
        .ffCard()
    }

    private func lastSessionCard(_ summary: ProgressOverloadEngine.LastSessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Session")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
                Spacer()
                Text(summary.workoutDate.relativeDisplay())
                    .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
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
        .padding(14)
        .ffCard()
    }

    private var allPRsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Records")
                .ffSectionHeader()
                .padding(.horizontal, 16)
            ForEach(vm.personalRecords) { pr in
                PRBadge(pr: pr)
                    .padding(.horizontal, 16)
            }
        }
    }

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
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}
