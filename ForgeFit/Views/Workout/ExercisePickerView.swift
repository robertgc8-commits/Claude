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

    let onSelect: (String, MuscleGroup, String?) -> Void

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
                                    Button {
                                        onSelect(template.name, template.muscleGroup, template.id)
                                        dismiss()
                                    } label: {
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
                    onSelect(customName, customGroup, nil)
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
