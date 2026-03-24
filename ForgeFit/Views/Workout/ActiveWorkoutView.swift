import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var vm: ActiveWorkoutViewModel?
    @State private var showingExercisePicker = false
    @State private var showingDiscardAlert = false
    @State private var showingFinishSummary = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    activeContent(vm: vm)
                } else {
                    ProgressView()
                        .tint(Color.ffAccent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.ffBackground)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { setupViewModel() }
    }

    @ViewBuilder
    private func activeContent(vm: ActiveWorkoutViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header info
                workoutHeader(vm: vm)

                // Exercises
                if vm.exercises.isEmpty {
                    emptyExerciseState
                } else {
                    ForEach(vm.exercises) { exercise in
                        ExerciseBlock(exercise: exercise, vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }

                // Add exercise button
                Button {
                    HapticFeedback.impact(.light)
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ffAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.ffAccent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .background(Color.ffBackground)
        .navigationTitle(vm.workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Discard") { showingDiscardAlert = true }
                    .foregroundStyle(Color.ffRed)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    HapticFeedback.success()
                    vm.finishWorkout()
                    showingFinishSummary = true
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.ffGreen)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { name, group, templateId in
                vm.addExercise(name: name, muscleGroup: group, templateId: templateId)
            }
        }
        .sheet(isPresented: $showingFinishSummary) {
            WorkoutSummaryView(vm: vm) {
                appState.showingActiveWorkout = false
            }
        }
        .alert("Discard workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                vm.discardWorkout()
                appState.showingActiveWorkout = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This workout will not be saved.")
        }
    }

    private func workoutHeader(vm: ActiveWorkoutViewModel) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.elapsedFormatted)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.ffAccent)
                Text("in progress")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            Spacer()
            if !vm.newPRs.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Color.ffGold)
                    Text("\(vm.newPRs.count) PR")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.ffGold)
                }
            }
        }
        .padding(16)
    }

    private var emptyExerciseState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 44))
                .foregroundStyle(Color.ffBorder)
            Text("Add your first exercise")
                .font(.system(size: 16))
                .foregroundStyle(Color.ffSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func setupViewModel() {
        let repo = WorkoutRepository(context: modelContext)
        let workout = repo.createWorkout(userId: appState.currentUserId, title: defaultWorkoutTitle())
        try? modelContext.save()
        vm = ActiveWorkoutViewModel(context: modelContext, userId: appState.currentUserId, workout: workout)
        vm?.loadSettings()
    }

    private func defaultWorkoutTitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning Workout" }
        if hour < 17 { return "Afternoon Workout" }
        return "Evening Workout"
    }
}

// MARK: - Exercise Block
private struct ExerciseBlock: View {
    let exercise: WorkoutExercise
    @ObservedObject var vm: ActiveWorkoutViewModel
    @State private var isExpanded = true

    var sets: [ExerciseSet] { (exercise.sets ?? []).sorted { $0.setNumber < $1.setNumber } }
    var workingSets: [ExerciseSet] { sets.filter { !$0.isWarmup } }
    var warmupSets: [ExerciseSet] { sets.filter { $0.isWarmup } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.ffText)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ffSubtext)
                }
                Spacer()

                // Last session hint
                if let summary = vm.lastSessionSummaries[exercise.exerciseName] {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Last: " + summary.bestSetDisplay)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.ffSubtext)
                        Text(summary.workoutDate.relativeDisplay())
                            .font(.system(size: 11))
                            .foregroundStyle(Color.ffSubtext.opacity(0.7))
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ffSubtext)
                        .padding(8)
                }

                Menu {
                    Button("Add Set") { vm.addSet(to: exercise) }
                    Button("Add Warmup Set") { vm.addWarmupSet(to: exercise) }
                    Divider()
                    Button("Remove Exercise", role: .destructive) { vm.removeExercise(exercise) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.ffSubtext)
                        .padding(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Suggestion banner
            if let suggestion = vm.suggestions[exercise.exerciseName], !isExpanded == false {
                Text(suggestion.rationale)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffAccent)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            if isExpanded {
                // Column headers
                HStack(spacing: 12) {
                    Text("Set").frame(width: 24)
                    Text("Prev").frame(width: 44)
                    Spacer()
                    Text("Weight").frame(width: 70)
                    Text("").frame(width: 10)
                    Text("Reps").frame(width: 60)
                    Text("").frame(width: 32)
                }
                .font(.system(size: 11))
                .foregroundStyle(Color.ffSubtext)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)

                Divider().background(Color.ffBorder).padding(.horizontal, 14)

                // Sets
                ForEach(workingSets) { set in
                    let isPR = vm.newPRs.contains { $0.setId == set.id }
                    ExerciseSetRow(
                        set: set,
                        setNumber: set.setNumber,
                        lastReps: vm.lastSessionSummaries[exercise.exerciseName]?.sets.first?.reps,
                        lastWeight: vm.lastSessionSummaries[exercise.exerciseName]?.sets.first?.weight,
                        isPR: isPR,
                        onComplete: { vm.completeSet(set, exercise: exercise) },
                        onDelete: { vm.removeSet(set, from: exercise) }
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)

                    if set.id != workingSets.last?.id {
                        Divider().background(Color.ffBorder).padding(.horizontal, 14)
                    }
                }

                // Add set button
                Button {
                    HapticFeedback.impact(.light)
                    vm.addSet(to: exercise)
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.ffAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
            }
        }
        .background(Color.ffSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
