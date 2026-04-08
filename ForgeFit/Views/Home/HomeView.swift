import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = HomeViewModel()

    // FEATURE 2: Calendar section collapse state
    @State private var calendarExpanded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Greeting
                    greetingHeader

                    // Stats row (This Week + Streak)
                    statsRow

                    // FEATURE 3: All-time stats row
                    allTimeStatsRow

                    // Streak card
                    StreakCard(status: vm.streakStatus)
                        .padding(.horizontal, 16)

                    // FEATURE 2: Collapsible calendar heatmap
                    calendarSection

                    // Recent PRs
                    if !vm.recentPRs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent PRs")
                                .ffSectionHeader()
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(vm.recentPRs) { pr in
                                        PRBadge(pr: pr, compact: true)
                                            .frame(width: 220)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // Recent workouts
                    if !vm.recentWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Recent Workouts")
                                    .ffSectionHeader()
                                Spacer()
                                NavigationLink("See All") {
                                    WorkoutHistoryView()
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.ffAccent)
                            }
                            .padding(.horizontal, 16)

                            ForEach(vm.recentWorkouts) { workout in
                                WorkoutCard(
                                    workout: workout,
                                    onTap: { /* navigate to detail */ },
                                    onDuplicate: {
                                        // Handled in WorkoutHistoryViewModel
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    } else {
                        emptyState
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.ffBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticFeedback.impact(.medium)
                        appState.showingActiveWorkout = true
                    } label: {
                        Label("Start Workout", systemImage: "plus")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.ffAccent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.loadDashboard()
        }
        .onChange(of: appState.showingActiveWorkout) { _, isShowing in
            if !isShowing {
                vm.configure(context: modelContext, userId: appState.currentUserId)
                vm.loadDashboard()
            }
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.system(size: 13))
                .foregroundStyle(Color.ffSubtext)
            Text("ForgeFit")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.ffText)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Stats Row (This Week + Streak)

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "This Week",
                value: "\(vm.weeklyWorkoutCount)",
                subtitle: "of \(vm.streakStatus.currentWeekTarget) goal",
                icon: "calendar",
                iconColor: .ffAccent
            )
            StatCard(
                title: "Streak",
                value: "\(vm.streakStatus.currentStreak)w",
                subtitle: vm.streakStatus.currentStreak == 0 ? "Start this week" : "consecutive",
                icon: "flame.fill",
                iconColor: .ffOrange
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Feature 3: All-Time Stats Row

    private var allTimeStatsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Time")
                .ffSectionHeader()
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                StatCard(
                    title: "Workouts",
                    value: "\(vm.totalWorkouts)",
                    subtitle: "completed",
                    icon: "dumbbell.fill",
                    iconColor: .ffAccent
                )
                StatCard(
                    title: "Volume",
                    value: vm.totalWeightLifted.allTimeVolumeDisplay(),
                    subtitle: "kg lifted",
                    icon: "chart.bar.fill",
                    iconColor: .ffOrange
                )
                StatCard(
                    title: "Time",
                    value: vm.totalWorkoutMinutes.totalTimeDisplay(),
                    subtitle: "in gym",
                    icon: "clock.fill",
                    iconColor: .ffGreen
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Feature 2: Collapsible Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    calendarExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Calendar")
                        .ffSectionHeader()
                    Spacer()
                    Image(systemName: calendarExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.ffSubtext)
                }
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if calendarExpanded {
                WorkoutCalendarView(calendarWorkouts: vm.calendarWorkouts)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(Color.ffBorder)
            Text("No workouts yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ffSubtext)
            Text("Tap + to log your first workout")
                .font(.system(size: 14))
                .foregroundStyle(Color.ffSubtext.opacity(0.7))
            FFButton(title: "Start Workout", style: .primary) {
                appState.showingActiveWorkout = true
            }
            .frame(width: 180)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }
}

// MARK: - Formatting helpers for all-time stats

private extension Double {
    func allTimeVolumeDisplay() -> String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fk", self / 1_000)
        }
        return String(format: "%.0f", self)
    }
}

private extension Int {
    func totalTimeDisplay() -> String {
        let hours = self / 60
        if hours >= 1 { return "\(hours)h" }
        return "\(self)m"
    }
}
