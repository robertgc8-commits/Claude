import Foundation
import SwiftData

@MainActor
final class ChallengeRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchActive(userId: String) throws -> [Challenge] {
        let active = ChallengeStatus.active
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { c in
                c.status == active && c.creatorUserId == userId
            },
            sortBy: [SortDescriptor(\.endDate)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAll(userId: String) throws -> [Challenge] {
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.creatorUserId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(id: String) throws -> Challenge? {
        let descriptor = FetchDescriptor<Challenge>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    // MARK: - Create

    func create(
        title: String,
        type: ChallengeType,
        goal: Double,
        endDate: Date,
        participantIds: [String],
        creatorUserId: String
    ) -> Challenge {
        let challenge = Challenge(
            title: title,
            challengeType: type,
            goal: goal,
            endDate: endDate,
            creatorUserId: creatorUserId,
            participantIds: participantIds
        )
        context.insert(challenge)
        return challenge
    }

    // MARK: - Update

    func updateProgress(_ challenge: Challenge, progress: Double) {
        challenge.myProgress = progress
        if progress >= challenge.goal { challenge.status = .completed }
    }

    func expire(olderThan date: Date = Date()) throws {
        let active = ChallengeStatus.active
        let descriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.status == active }
        )
        let items = try context.fetch(descriptor)
        for c in items where c.endDate < date { c.status = .expired }
    }

    // MARK: - Delete

    func delete(_ challenge: Challenge) {
        context.delete(challenge)
    }

    // MARK: - Save

    func save() throws { try context.save() }
}
