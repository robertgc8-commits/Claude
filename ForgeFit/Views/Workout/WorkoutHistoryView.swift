import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm: WorkoutHistoryViewModel

    @State private var selectedWorkout: Workout?
    @State private var showingStartNew = false

    init() {
        _vm = StateObject(wrappedValue: WorkoutHistoryViewModel(
            context: ModelContext(try! ModelContainer(for: Workout.self)),
            userId: ""
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.workouts.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    workoutList
                }
            }
            .background(Color.ffBackground)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showingActiveWorkout = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.ffAccent)
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search workouts")
        }
        .preferredColorScheme(.dark)
        .onAppear { vm.load() }
    }

    private var workoutList: some View {
        List {
            ForEach(vm.groupedWorkouts, id: \.key) { section in
                Section(section.key) {
                    ForEach(section.value) { workout in
                        WorkoutCard(
                            workout: workout,
                            onTap: { selectedWorkout = workout },
                            onDuplicate: {
                                let copy = vm.duplicateWorkout(workout)
                                HapticFeedback.success()
                                _ = copy
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                vm.deleteWorkout(workout)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 52))
                .foregroundStyle(Color.ffBorder)
            Text("No workouts logged yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ffSubtext)
            FFButton(title: "Log Your First Workout", style: .primary) {
                appState.showingActiveWorkout = true
            }
            .frame(width: 220)
            Spacer()
        }
    }
}

// MARK: - Workout Detail
struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats
                    HStack(spacing: 12) {
                        detailStat("\(workout.exerciseCount)", label: "Exercises")
                        detailStat("\(workout.totalSets)", label: "Sets")
                        detailStat(workout.totalVolume.volumeDisplay(), label: "Volume")
                        if let d = workout.durationSeconds {
                            detailStat(d.durationFormatted, label: "Duration")
                        }
                    }
                    .padding(.horizontal, 16)

                    // Exercises
                    ForEach((workout.exercises ?? []).sorted { $0.order < $1.order }) { exercise in
                        exerciseDetail(exercise)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.ffBackground)
            .navigationTitle(workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.ffAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func detailStat(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Color.ffText)
            Text(label).font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .ffCard()
    }

    private func exerciseDetail(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.ffText)
                Spacer()
                Text(exercise.muscleGroup.rawValue)
                    .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
            }

            ForEach(exercise.completedSets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                    Spacer()
                    Text("\(String(format: "%.1f", set.weight))kg × \(set.reps)")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.ffText)
                }
            }
        }
        .padding(14)
        .ffCard()
    }
}
