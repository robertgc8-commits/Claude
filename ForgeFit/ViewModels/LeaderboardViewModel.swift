import Foundation
import SwiftData

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var selectedType: LeaderboardType = .weeklyVolume
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var weekStartLabel: String = ""

    private var workoutRepo: WorkoutRepository?
    private var friendRepo: FriendRepository?
    private var userRepo: UserRepository?
    private var userId: String = ""
    private let socialService: SocialServiceProtocol

    init(socialService: SocialServiceProtocol = SocialServiceProvider.shared) {
        self.socialService = socialService
    }

    func configure(context: ModelContext, userId: String) {
        self.workoutRepo = WorkoutRepository(context: context)
        self.friendRepo = FriendRepository(context: context)
        self.userRepo = UserRepository(context: context)
        self.userId = userId
        updateWeekLabel()
    }

    func load() {
        Task { await fetchLeaderboard() }
    }

    func selectType(_ type: LeaderboardType) {
        selectedType = type
        Task { await fetchLeaderboard() }
    }

    private func fetchLeaderboard() async {
        guard let workoutRepo, let friendRepo, let userRepo else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let friends = try friendRepo.fetchAcceptedFriends(userId: userId)
            let user = try userRepo.fetchCurrentUser(userId: userId)
            let displayName = user?.displayName ?? "You"
            let username = user?.username ?? userId

            let currentValue = try computeCurrentUserValue(workoutRepo: workoutRepo)

            entries = try await socialService.fetchLeaderboard(
                type: selectedType,
                friends: friends,
                currentUserId: userId,
                currentUserDisplayName: displayName,
                currentUserUsername: username,
                currentUserValue: currentValue
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func computeCurrentUserValue(workoutRepo: WorkoutRepository) throws -> Double {
        let thisWeek = try workoutRepo.fetchWorkoutsThisWeek(userId: userId)
        switch selectedType {
        case .weeklyVolume:
            return thisWeek.reduce(0) { total, w in
                total + (w.exercises ?? []).flatMap { $0.completedSets }.reduce(0) { $0 + $1.weight * Double($1.reps) }
            }
        case .weeklyWorkouts:
            return Double(thisWeek.count)
        }
    }

    private func updateWeekLabel() {
        let weekStart = StreakEngine.weekStart(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        weekStartLabel = "Week of \(fmt.string(from: weekStart))"
    }

    func formattedValue(_ value: Double) -> String {
        switch selectedType {
        case .weeklyVolume:
            return value >= 1000
                ? String(format: "%.1fk kg", value / 1000)
                : String(format: "%.0f kg", value)
        case .weeklyWorkouts:
            return "\(Int(value))"
        }
    }
}
