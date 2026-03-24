import SwiftUI

struct WorkoutSummaryView: View {
    @ObservedObject var vm: ActiveWorkoutViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.ffGreen)
                        Text("Workout Complete")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.ffText)
                        if let duration = vm.workout.durationSeconds {
                            Text(duration.durationFormatted)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.ffSubtext)
                        }
                    }
                    .padding(.top, 8)

                    // Stats
                    HStack(spacing: 12) {
                        summaryStatBox("\(vm.workout.exerciseCount)", label: "Exercises")
                        summaryStatBox("\(vm.workout.totalSets)", label: "Sets")
                        summaryStatBox(vm.workout.totalVolume.volumeDisplay(), label: "Volume")
                    }
                    .padding(.horizontal, 16)

                    // PRs
                    if !vm.newPRs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personal Records")
                                .ffSectionHeader()
                                .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                ForEach(vm.newPRs) { pr in
                                    PRBadge(pr: pr)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }

                    // Exercises summary
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Exercises")
                            .ffSectionHeader()
                            .padding(.horizontal, 16)

                        ForEach(vm.exercises) { exercise in
                            exerciseSummaryRow(exercise)
                                .padding(.horizontal, 16)
                        }
                    }

                    // Newly unlocked achievements
                    if !vm.newlyUnlockedAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Unlocked")
                                .ffSectionHeader()
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.newlyUnlockedAchievements) { def in
                                        AchievementBadge(definition: def, isUnlocked: true, unlockDate: Date())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.ffBackground)
            .navigationTitle(vm.workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ffAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func summaryStatBox(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ffText)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.ffSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .ffCard()
    }

    private func exerciseSummaryRow(_ exercise: WorkoutExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ffText)
                let count = exercise.completedSets.count
                Text("\(count) set\(count == 1 ? "" : "s") · \(exercise.totalVolume.volumeDisplay())kg")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            Spacer()
            Text(exercise.muscleGroup.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.ffAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.ffAccent.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(12)
        .ffCard()
    }
}
