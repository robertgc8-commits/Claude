import Foundation
import SwiftData

@MainActor
final class ChallengeViewModel: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Create challenge form
    @Published var newTitle: String = ""
    @Published var newType: ChallengeType = .volume
    @Published var newGoal: Double = 5000
    @Published var newEndDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var showingCreate = false

    // Challenge leaderboard
    @Published var leaderboardEntries: [ChallengeParticipantEntry] = []
    @Published var isLoadingLeaderboard = false

    private var challengeRepo: ChallengeRepository?
    private var workoutRepo: WorkoutRepository?
    private var userRepo: UserRepository?
    private var friendRepo: FriendRepository?
    private var userId: String = ""
    private let socialService: SocialServiceProtocol

    init(socialService: SocialServiceProtocol = SocialServiceProvider.shared) {
        self.socialService = socialService
    }

    func configure(context: ModelContext, userId: String) {
        self.challengeRepo = ChallengeRepository(context: context)
        self.workoutRepo = WorkoutRepository(context: context)
        self.userRepo = UserRepository(context: context)
        self.friendRepo = FriendRepository(context: context)
        self.userId = userId
    }

    // MARK: - Load

    func load() {
        guard let challengeRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try challengeRepo.expire()
            challenges = try challengeRepo.fetchAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create

    var canCreate: Bool {
        !newTitle.trimmingCharacters(in: .whitespaces).isEmpty && newGoal > 0 && newEndDate > Date()
    }

    func createChallenge(inviteAllFriends: Bool = false) {
        guard canCreate, let challengeRepo else { return }

        var participantIds = [userId]
        if inviteAllFriends, let friendRepo {
            let friends = (try? friendRepo.fetchAcceptedFriends(userId: userId)) ?? []
            participantIds += friends.map { $0.friendUserId }
        }

        let challenge = challengeRepo.create(
            title: newTitle.trimmingCharacters(in: .whitespaces),
            type: newType,
            goal: newGoal,
            endDate: newEndDate,
            participantIds: participantIds,
            creatorUserId: userId
        )
        try? challengeRepo.save()

        // Notify backend + invitees
        Task {
            try? await socialService.notifyChallengeCreated(
                challengeId: challenge.id,
                title: challenge.title,
                creatorUserId: userId,
                inviteeIds: participantIds.filter { $0 != userId }
            )
        }

        resetForm()
        showingCreate = false
        load()
    }

    // MARK: - Progress

    /// Recomputes the user's challenge progress from their local workout history.
    func syncProgress(for challenge: Challenge) {
        guard let challengeRepo, let workoutRepo else { return }
        let workouts = (try? workoutRepo.fetchCompletedWorkouts(userId: userId)) ?? []
        let relevantWorkouts = workouts.filter { ($0.completedAt ?? $0.startedAt) >= challenge.startDate }

        let progress: Double
        switch challenge.challengeType {
        case .volume:
            progress = relevantWorkouts.reduce(0) { total, w in
                total + (w.exercises ?? []).flatMap { $0.completedSets }.reduce(0) { $0 + $1.weight * Double($1.reps) }
            }
        case .workoutCount:
            progress = Double(relevantWorkouts.count)
        }

        challengeRepo.updateProgress(challenge, progress: progress)
        try? challengeRepo.save()
        load()
    }

    // MARK: - Leaderboard

    func loadLeaderboard(for challenge: Challenge) {
        let myProgress = challenge.myProgress
        let displayName = (try? userRepo?.fetchCurrentUser(userId: userId))?.displayName ?? "You"
        let username = (try? userRepo?.fetchCurrentUser(userId: userId))?.username ?? userId
        isLoadingLeaderboard = true
        Task {
            do {
                self.leaderboardEntries = try await socialService.fetchChallengeLeaderboard(
                    challengeId: challenge.id,
                    myUserId: userId,
                    myDisplayName: displayName,
                    myUsername: username,
                    myProgress: myProgress
                )
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoadingLeaderboard = false
        }
    }

    // MARK: - Delete

    func delete(_ challenge: Challenge) {
        guard let challengeRepo else { return }
        challengeRepo.delete(challenge)
        try? challengeRepo.save()
        load()
    }

    // MARK: - Helpers

    func progressLabel(for challenge: Challenge) -> String {
        let unit = challenge.challengeType.unit
        if challenge.challengeType == .volume {
            return "\(String(format: "%.0f", challenge.myProgress)) / \(String(format: "%.0f", challenge.goal)) \(unit)"
        }
        return "\(Int(challenge.myProgress)) / \(Int(challenge.goal)) \(unit)"
    }

    private func resetForm() {
        newTitle = ""
        newType = .volume
        newGoal = 5000
        newEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
}
