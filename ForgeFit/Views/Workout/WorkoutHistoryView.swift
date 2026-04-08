import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = WorkoutHistoryViewModel()

    @State private var selectedWorkout: Workout?
    @State private var showingDateFilter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle group filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", isSelected: vm.filterMuscleGroup == nil) {
                            vm.filterMuscleGroup = nil
                        }
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            filterChip(group.rawValue, isSelected: vm.filterMuscleGroup == group) {
                                vm.filterMuscleGroup = vm.filterMuscleGroup == group ? nil : group
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.ffBackground)

                // Active date filter banner
                if vm.isDateFiltered {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.ffAccent)
                            .font(.system(size: 12))
                        Text(dateFilterLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.ffAccent)
                        Spacer()
                        Button("Clear") { vm.clearDateFilter() }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ffSubtext)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.ffAccent.opacity(0.08))
                }

                Divider().background(Color.ffBorder)

                Group {
                    if vm.workouts.isEmpty && !vm.isLoading {
                        emptyState
                    } else if vm.filtered.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Text("No workouts match the current filter")
                                .font(.system(size: 16)).foregroundStyle(Color.ffSubtext)
                            Spacer()
                        }
                    } else {
                        workoutList
                    }
                }
            }
            .background(Color.ffBackground)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            showingDateFilter = true
                        } label: {
                            Image(systemName: vm.isDateFiltered ? "calendar.badge.checkmark" : "calendar")
                                .font(.system(size: 16))
                                .foregroundStyle(vm.isDateFiltered ? Color.ffAccent : Color.ffSubtext)
                        }
                        Button {
                            appState.showingActiveWorkout = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.ffAccent)
                        }
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search workouts")
            .sheet(isPresented: $showingDateFilter) {
                DateFilterSheet(startDate: $vm.filterStartDate, endDate: $vm.filterEndDate)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
        .onChange(of: appState.showingActiveWorkout) { _, isShowing in
            if !isShowing {
                vm.configure(context: modelContext, userId: appState.currentUserId)
                vm.load()
            }
        }
    }

    private var dateFilterLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        switch (vm.filterStartDate, vm.filterEndDate) {
        case (let s?, let e?): return "\(fmt.string(from: s)) – \(fmt.string(from: e))"
        case (let s?, nil):    return "From \(fmt.string(from: s))"
        case (nil, let e?):    return "Until \(fmt.string(from: e))"
        default:               return ""
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.ffSubtext)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.ffAccent : Color.ffSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                                let _ = vm.duplicateWorkout(workout)
                                HapticFeedback.success()
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
            WorkoutDetailView(workout: workout, onUpdate: { title, date in
                vm.updateWorkout(workout, title: title, date: date)
                vm.recomputePRs(for: workout)
            })
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

// MARK: - Date Filter Sheet

private struct DateFilterSheet: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Environment(\.dismiss) private var dismiss

    @State private var localStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var localEnd: Date = Date()
    @State private var useStart = false
    @State private var useEnd = false

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Toggle("Set start date", isOn: $useStart)
                        .tint(Color.ffAccent)
                    if useStart {
                        DatePicker("Start", selection: $localStart, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }
                }
                .listRowBackground(Color.ffSurface)

                Section("Until") {
                    Toggle("Set end date", isOn: $useEnd)
                        .tint(Color.ffAccent)
                    if useEnd {
                        DatePicker("End", selection: $localEnd, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }
                }
                .listRowBackground(Color.ffSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.ffBackground)
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.ffSubtext)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        startDate = useStart ? localStart : nil
                        endDate = useEnd ? localEnd : nil
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ffAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let s = startDate { localStart = s; useStart = true }
            if let e = endDate { localEnd = e; useEnd = true }
        }
    }
}

// MARK: - Workout Detail

struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    let onUpdate: (String?, Date?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editTitle: String = ""
    @State private var editDate: Date = Date()

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

                    if isEditing {
                        editFields
                            .padding(.horizontal, 16)
                    }

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
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                        .foregroundStyle(Color.ffSubtext)
                    } else {
                        Button("Done") { dismiss() }.foregroundStyle(Color.ffAccent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            onUpdate(editTitle, editDate)
                            isEditing = false
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ffAccent)
                    } else {
                        Button("Edit") {
                            editTitle = workout.title
                            editDate = workout.startedAt
                            isEditing = true
                        }
                        .foregroundStyle(Color.ffSubtext)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var editFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.ffSubtext)
                TextField("Workout title", text: $editTitle)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.ffText)
                    .padding(12)
                    .background(Color.ffSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Date")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.ffSubtext)
                DatePicker("", selection: $editDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
            }

            Text("Saving will recompute personal records for this workout.")
                .font(.system(size: 11))
                .foregroundStyle(Color.ffSubtext)
        }
        .padding(14)
        .background(Color.ffSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                if exercise.supersetGroupId != nil {
                    Text("SS")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.ffPurple)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(exercise.muscleGroup.rawValue)
                    .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
            }

            ForEach(exercise.completedSets) { set in
                HStack {
                    HStack(spacing: 4) {
                        Text("Set \(set.setNumber)")
                            .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                        if set.isDropSet {
                            Text("DS")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color.ffOrange)
                                .clipShape(Capsule())
                        }
                        if set.isWarmup {
                            Text("W")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Color.ffSubtext)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Text("\(String(format: "%.1f", set.weight))kg × \(set.reps)")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.ffText)
                    if let rpe = set.rpe {
                        Text("RPE \(rpe)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.ffSubtext)
                    }
                }
            }
        }
        .padding(14)
        .ffCard()
    }
}
