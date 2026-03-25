import SwiftUI
import SwiftData

struct AchievementsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm: AchievementsViewModel
    @State private var selectedAchievement: AchievementDefinition?

    init() {
        _vm = StateObject(wrappedValue: AchievementsViewModel(
            context: ModelContext(try! ModelContainer(for: AchievementUnlock.self)),
            userId: ""
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Progress header
                    progressHeader
                        .padding(.horizontal, 16)

                    // Category filter
                    categoryFilter

                    // Achievements grid
                    achievementGrid
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            .background(Color.ffBackground)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
        .sheet(item: $selectedAchievement) { definition in
            AchievementDetailSheet(definition: definition, vm: vm)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(vm.unlockedCount) of \(vm.totalCount) unlocked")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ffText)
                Spacer()
                Text("\(Int(vm.progressPercent * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ffAccent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ffSurface2).frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(colors: [Color.ffAccent, Color.ffAccent.opacity(0.7)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * vm.progressPercent, height: 6)
                        .animation(.spring(response: 0.6), value: vm.progressPercent)
                }
            }
            .frame(height: 6)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: "All")
                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                    categoryChip(cat, label: cat.rawValue)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func categoryChip(_ cat: AchievementCategory?, label: String) -> some View {
        Button {
            vm.selectedCategory = cat
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(vm.selectedCategory == cat ? .white : Color.ffSubtext)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(vm.selectedCategory == cat ? (cat?.swiftColor ?? Color.ffAccent) : Color.ffSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var achievementGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(vm.displayDefinitions) { definition in
                Button {
                    selectedAchievement = definition
                } label: {
                    AchievementBadge(
                        definition: definition,
                        isUnlocked: vm.isUnlocked(definition),
                        unlockDate: vm.unlockDate(for: definition)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AchievementDetailSheet: View {
    let definition: AchievementDefinition
    @ObservedObject var vm: AchievementsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                AchievementBadge(
                    definition: definition,
                    isUnlocked: vm.isUnlocked(definition),
                    unlockDate: vm.unlockDate(for: definition),
                    size: .large
                )

                VStack(spacing: 8) {
                    Text(definition.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.ffText)
                    Text(definition.description)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.ffSubtext)
                        .multilineTextAlignment(.center)

                    Text(definition.category.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(definition.category.swiftColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(definition.category.swiftColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                if vm.isUnlocked(definition), let date = vm.unlockDate(for: definition) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.ffGreen)
                        Text("Unlocked " + date.workoutDateDisplay())
                            .font(.system(size: 13))
                            .foregroundStyle(Color.ffSubtext)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.ffSubtext)
                        Text("Not yet unlocked")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.ffSubtext)
                    }
                }
                Spacer()
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .background(Color.ffBackground)
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
