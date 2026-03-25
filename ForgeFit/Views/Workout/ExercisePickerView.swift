import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup? = nil
    @State private var showingCustom = false
    @State private var customName = ""
    @State private var customGroup: MuscleGroup = .other

    let onSelect: (String, MuscleGroup, String?, [(reps: Int, weight: Double)]) -> Void

    private var filtered: [ExerciseTemplate] {
        ExerciseTemplate.presets.filter { template in
            let matchesSearch = searchText.isEmpty || template.name.localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedGroup == nil || template.muscleGroup == selectedGroup
            return matchesSearch && matchesGroup
        }.sorted { $0.name < $1.name }
    }

    private var grouped: [MuscleGroup: [ExerciseTemplate]] {
        Dictionary(grouping: filtered) { $0.muscleGroup }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", isSelected: selectedGroup == nil) {
                            selectedGroup = nil
                        }
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            filterChip(group.rawValue, isSelected: selectedGroup == group) {
                                selectedGroup = selectedGroup == group ? nil : group
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider().background(Color.ffBorder)

                List {
                    if searchText.isEmpty || "custom".contains(searchText.lowercased()) {
                        Section {
                            Button {
                                showingCustom = true
                            } label: {
                                Label("Create custom exercise", systemImage: "plus.circle")
                                    .foregroundStyle(Color.ffAccent)
                            }
                        }
                    }

                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        if let templates = grouped[group], !templates.isEmpty {
                            Section(group.rawValue) {
                                ForEach(templates) { template in
                                    NavigationLink(destination: ExerciseSetupView(
                                        name: template.name,
                                        muscleGroup: template.muscleGroup,
                                        templateId: template.id,
                                        onAdd: onSelect,
                                        dismissPicker: { dismiss() }
                                    )) {
                                        HStack {
                                            Text(template.name)
                                                .foregroundStyle(Color.ffText)
                                            Spacer()
                                            Image(systemName: template.equipment == .barbell ? "scalemass" : "dumbbell")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.ffSubtext)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.ffBackground)
            }
            .background(Color.ffBackground)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ffSubtext)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingCustom) {
            customExerciseSheet
        }
    }

    private var customExerciseSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                FFTextField(placeholder: "Exercise Name", text: $customName)
                    .padding(.horizontal, 20)

                Picker("Muscle Group", selection: $customGroup) {
                    ForEach(MuscleGroup.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.wheel)

                FFButton(title: "Add Exercise", style: .primary) {
                    guard !customName.isEmpty else { return }
                    onSelect(customName, customGroup, nil, [(reps: 8, weight: 0)])
                    showingCustom = false
                    dismiss()
                }
                .padding(.horizontal, 20)
                Spacer()
            }
            .padding(.top, 20)
            .background(Color.ffBackground)
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showingCustom = false }
                        .foregroundStyle(Color.ffSubtext)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.ffSubtext)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.ffAccent : Color.ffSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Setup View

private struct ExerciseSetupView: View {
    let name: String
    let muscleGroup: MuscleGroup
    let templateId: String?
    let onAdd: (String, MuscleGroup, String?, [(reps: Int, weight: Double)]) -> Void
    let dismissPicker: () -> Void

    private struct SetEntry: Identifiable {
        let id = UUID()
        var reps: Int = 8
        var weight: Double = 0
    }

    @State private var sets: [SetEntry] = [SetEntry()]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Exercise info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.ffText)
                        Text(muscleGroup.rawValue)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.ffSubtext)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Sets card
                VStack(spacing: 0) {
                    // Column headers
                    HStack(spacing: 12) {
                        Text("SET").frame(width: 28, alignment: .leading)
                        Spacer()
                        Text("WEIGHT").frame(width: 80, alignment: .center)
                        Text("×").frame(width: 16)
                        Text("REPS").frame(width: 70, alignment: .center)
                        Spacer().frame(width: 32)
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.ffSubtext)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    Divider().background(Color.ffBorder)

                    ForEach($sets) { $entry in
                        let index = sets.firstIndex(where: { $0.id == entry.id }) ?? 0
                        SetupSetRow(
                            setNumber: index + 1,
                            reps: $entry.reps,
                            weight: $entry.weight,
                            canDelete: sets.count > 1,
                            onDelete: { sets.removeAll { $0.id == entry.id } }
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if index < sets.count - 1 {
                            Divider().background(Color.ffBorder).padding(.horizontal, 14)
                        }
                    }

                    Divider().background(Color.ffBorder)

                    Button {
                        HapticFeedback.impact(.light)
                        let last = sets.last
                        sets.append(SetEntry(reps: last?.reps ?? 8, weight: last?.weight ?? 0))
                    } label: {
                        Label("Add Set", systemImage: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.ffAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.ffSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 100)
        }
        .background(Color.ffBackground)
        .navigationTitle("Configure Sets")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            FFButton(title: "Add to Workout", style: .primary) {
                HapticFeedback.success()
                let initialSets = sets.map { (reps: $0.reps, weight: $0.weight) }
                onAdd(name, muscleGroup, templateId, initialSets)
                dismissPicker()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.ffBackground)
        }
    }
}

// MARK: - Setup Set Row

private struct SetupSetRow: View {
    let setNumber: Int
    @Binding var reps: Int
    @Binding var weight: Double
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.ffAccent)
                .frame(width: 28, alignment: .leading)

            Spacer()

            // Weight
            HStack(spacing: 4) {
                TextField("0", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                Text("kg")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color.ffSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("×")
                .foregroundStyle(Color.ffSubtext)
                .frame(width: 16)

            // Reps
            HStack(spacing: 4) {
                TextField("0", value: $reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 36)
                Text("reps")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color.ffSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.ffRed)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
            .opacity(canDelete ? 1 : 0.25)
            .disabled(!canDelete)
        }
    }
}
