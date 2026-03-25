import SwiftUI
import SwiftData

struct WorkoutTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let userId: String
    let onSelect: (WorkoutTemplate) -> Void

    @State private var templates: [WorkoutTemplate] = []
    @State private var showingNewTemplateAlert = false
    @State private var newTemplateName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var templateRepo: WorkoutTemplateRepository {
        WorkoutTemplateRepository(context: modelContext)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()

                if templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ffSubtext)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newTemplateName = ""
                        showingNewTemplateAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.ffAccent)
                    }
                }
            }
            .alert("New Template", isPresented: $showingNewTemplateAlert) {
                TextField("Template name", text: $newTemplateName)
                Button("Create") { createBlankTemplate() }
                    .disabled(newTemplateName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give your blank template a name.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { loadTemplates() }
    }

    // MARK: - Template List

    private var templateList: some View {
        List {
            ForEach(templates) { template in
                Button {
                    HapticFeedback.impact(.light)
                    onSelect(template)
                    dismiss()
                } label: {
                    TemplateRow(template: template)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.ffSurface)
                .listRowSeparatorTint(Color.ffBorder)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete { indexSet in
                deleteTemplates(at: indexSet)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.ffBackground)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.ffBorder)

            Text("No templates yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ffText)

            Text("Save a workout as a template to reuse it.")
                .font(.system(size: 14))
                .foregroundStyle(Color.ffSubtext)
                .multilineTextAlignment(.center)

            Button {
                newTemplateName = ""
                showingNewTemplateAlert = true
            } label: {
                Label("Create Blank Template", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ffAccent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.ffAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func loadTemplates() {
        templates = (try? templateRepo.fetchTemplates(userId: userId)) ?? []
    }

    private func createBlankTemplate() {
        let name = newTemplateName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let template = templateRepo.createBlankTemplate(userId: userId, name: name)
        try? templateRepo.save()
        templates.insert(template, at: 0)
        HapticFeedback.success()
    }

    private func deleteTemplates(at indexSet: IndexSet) {
        for index in indexSet {
            templateRepo.deleteTemplate(templates[index])
        }
        try? templateRepo.save()
        templates.remove(atOffsets: indexSet)
        HapticFeedback.impact(.medium)
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Name + use count badge
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ffText)
                    .lineLimit(1)

                Spacer()

                if template.useCount > 0 {
                    Text("\(template.useCount)×")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.ffAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.ffAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Exercise count + last used
            HStack(spacing: 12) {
                Label(exerciseCountLabel(template.exerciseCount),
                      systemImage: "dumbbell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)

                if let lastUsed = template.lastUsedAt {
                    Label(lastUsed.relativeDisplay(),
                          systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ffSubtext)
                }
            }

            // Muscle group chips
            let groups = template.muscleGroups
            if !groups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(groups, id: \.self) { group in
                            MuscleGroupChip(group: group)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func exerciseCountLabel(_ count: Int) -> String {
        count == 1 ? "1 exercise" : "\(count) exercises"
    }
}

// MARK: - Muscle Group Chip

private struct MuscleGroupChip: View {
    let group: MuscleGroup

    var body: some View {
        Text(group.rawValue)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(chipColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(chipColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var chipColor: Color {
        switch group {
        case .chest:               return .ffRed
        case .back:                return .ffAccent
        case .shoulders:           return .ffOrange
        case .biceps, .triceps:    return .ffPurple
        case .legs, .glutes:       return .ffGreen
        case .core:                return .ffGold
        case .cardio:              return .ffRed
        case .fullBody:            return .ffAccent
        case .other:               return .ffSubtext
        }
    }
}

