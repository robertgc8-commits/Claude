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
    @State private var showingNotes = false

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
                workoutHeader(vm: vm)

                if vm.exercises.isEmpty {
                    emptyExerciseState
                } else {
                    ForEach(vm.exercises) { exercise in
                        ExerciseBlock(exercise: exercise, vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }

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
                .padding(.bottom, 120)
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
                HStack(spacing: 16) {
                    Button {
                        showingNotes = true
                    } label: {
                        Image(systemName: vm.workout.notes?.isEmpty == false ? "note.text" : "note.text.badge.plus")
                            .foregroundStyle(vm.workout.notes?.isEmpty == false ? Color.ffAccent : Color.ffSubtext)
                    }
                    Button("Finish") {
                        HapticFeedback.success()
                        vm.finishWorkout()
                        showingFinishSummary = true
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.ffGreen)
                }
            }
        }
        // Rest timer overlay
        .overlay(alignment: .bottom) {
            if let remaining = vm.restTimerRemaining {
                RestTimerBanner(
                    remaining: remaining,
                    total: vm.restTimerTotal,
                    onSkip: { vm.skipRestTimer() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.restTimerRemaining != nil)
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { name, group, templateId, initialSets in
                vm.addExercise(name: name, muscleGroup: group, templateId: templateId, initialSets: initialSets)
            }
        }
        .sheet(isPresented: $showingFinishSummary) {
            WorkoutSummaryView(vm: vm) {
                appState.showingActiveWorkout = false
            }
        }
        .sheet(isPresented: $showingNotes) {
            WorkoutNotesSheet(workout: vm.workout)
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
                    Image(systemName: "trophy.fill").foregroundStyle(Color.ffGold)
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

// MARK: - Rest Timer Banner

private struct RestTimerBanner: View {
    let remaining: Int
    let total: Int
    let onSkip: () -> Void

    private var progress: Double { Double(remaining) / Double(total) }
    private var minutes: Int { remaining / 60 }
    private var seconds: Int { remaining % 60 }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.ffBorder, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                Text(remaining <= 0 ? "Go!" : "\(minutes > 0 ? "\(minutes):" : "")\(String(format: minutes > 0 ? "%02d" : "%d", seconds))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(timerColor)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(remaining <= 0 ? "Rest complete" : "Resting…")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ffText)
                Text(remaining <= 0 ? "Time to crush the next set" : "Next set in \(remaining)s")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }

            Spacer()

            Button("Skip") { onSkip() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ffSubtext)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.ffSurface2)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.ffSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    private var timerColor: Color {
        if remaining <= 0 { return .ffGreen }
        if Double(remaining) / Double(total) < 0.25 { return .ffRed }
        return .ffAccent
    }
}

// MARK: - Workout Notes Sheet

private struct WorkoutNotesSheet: View {
    @Bindable var workout: Workout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.ffBackground.ignoresSafeArea()
                TextEditor(text: Binding(
                    get: { workout.notes ?? "" },
                    set: { workout.notes = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 16))
                .foregroundStyle(Color.ffText)
                .scrollContentBackground(.hidden)
                .padding(16)

                if workout.notes?.isEmpty != false {
                    Text("Add notes about this workout…")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.ffSubtext.opacity(0.5))
                        .padding(22)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Workout Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.ffAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Exercise Block

private struct ExerciseBlock: View {
    @Bindable var exercise: WorkoutExercise
    @ObservedObject var vm: ActiveWorkoutViewModel
    @State private var isExpanded = true

    var sets: [ExerciseSet] { (exercise.sets ?? []).filter { !$0.isWarmup }.sorted { $0.setNumber < $1.setNumber } }
    var warmupSets: [ExerciseSet] { (exercise.sets ?? []).filter { $0.isWarmup }.sorted { $0.setNumber < $1.setNumber } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
                if let summary = vm.lastSessionSummaries[exercise.exerciseName] {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Last: " + summary.bestSetDisplay)
                            .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
                        Text(summary.workoutDate.relativeDisplay())
                            .font(.system(size: 11)).foregroundStyle(Color.ffSubtext.opacity(0.7))
                    }
                }
                Button {
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12)).foregroundStyle(Color.ffSubtext).padding(8)
                }
                Menu {
                    Button("Add Set") { vm.addSet(to: exercise) }
                    Button("Add Warmup Set") { vm.addWarmupSet(to: exercise) }
                    Divider()
                    Button("Remove Exercise", role: .destructive) { vm.removeExercise(exercise) }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 16)).foregroundStyle(Color.ffSubtext).padding(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            if let suggestion = vm.suggestions[exercise.exerciseName], isExpanded {
                Text(suggestion.rationale)
                    .font(.system(size: 12)).foregroundStyle(Color.ffAccent)
                    .padding(.horizontal, 14).padding(.bottom, 8)
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
                .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
                .padding(.horizontal, 14).padding(.bottom, 4)

                Divider().background(Color.ffBorder).padding(.horizontal, 14)

                ForEach(sets) { set in
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
                    if set.id != sets.last?.id {
                        Divider().background(Color.ffBorder).padding(.horizontal, 14)
                    }
                }

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
