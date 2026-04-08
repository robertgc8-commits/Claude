import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    var onTap: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.ffText)
                        Text(workout.startedAt.workoutDateDisplay())
                            .font(.system(size: 13))
                            .foregroundStyle(Color.ffSubtext)
                    }
                    Spacer()
                    if let duration = workout.durationSeconds {
                        Label(duration.durationFormatted, systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.ffSubtext)
                    }
                }

                // Muscle group chips
                let groups = Set((workout.exercises ?? []).map { $0.muscleGroup })
                if !groups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(groups), id: \.self) { group in
                                Text(group.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.ffAccent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.ffAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    workoutStat("\(workout.exerciseCount)", label: "exercises")
                    workoutStat("\(workout.totalSets)", label: "sets")
                    workoutStat(workout.totalVolume.volumeDisplay(), label: "kg total")
                    Spacer()
                    if let onDuplicate {
                        Button(action: onDuplicate) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.ffSubtext)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .ffCard()
        }
        .buttonStyle(.plain)
    }

    private func workoutStat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.ffText)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.ffSubtext)
        }
    }
}
