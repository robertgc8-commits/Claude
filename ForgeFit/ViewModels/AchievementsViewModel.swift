import Foundation
import SwiftData

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var unlocked: [AchievementUnlock] = []
    @Published var selectedCategory: AchievementCategory? = nil
    @Published var isLoading = false

    private let context: ModelContext
    private let userId: String

    init(context: ModelContext, userId: String) {
        self.context = context
        self.userId = userId
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        let descriptor = FetchDescriptor<AchievementUnlock>(
            predicate: #Predicate { $0.userId == self.userId },
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )
        unlocked = (try? context.fetch(descriptor)) ?? []
    }

    var unlockedIds: Set<String> { Set(unlocked.map { $0.achievementId }) }

    var displayDefinitions: [AchievementDefinition] {
        let all = AchievementDefinition.all
        if let category = selectedCategory {
            return all.filter { $0.category == category }
        }
        return all
    }

    func isUnlocked(_ definition: AchievementDefinition) -> Bool {
        unlockedIds.contains(definition.id)
    }

    func unlockDate(for definition: AchievementDefinition) -> Date? {
        unlocked.first { $0.achievementId == definition.id }?.unlockedAt
    }

    var unlockedCount: Int { unlocked.count }
    var totalCount: Int { AchievementDefinition.all.count }
    var progressPercent: Double {
        totalCount > 0 ? Double(unlockedCount) / Double(totalCount) : 0
    }
}
