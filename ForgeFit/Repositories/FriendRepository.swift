import Foundation
import SwiftData

@MainActor
final class FriendRepository {
    private let context: ModelContext
    private let syncService: SyncServiceProtocol

    init(context: ModelContext, syncService: SyncServiceProtocol = MockSyncService()) {
        self.context = context
        self.syncService = syncService
    }

    func fetchFriends(userId: String) throws -> [FriendRelationship] {
        let descriptor = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate { $0.friendUserId != userId },
            sortBy: [SortDescriptor(\.friendDisplayName)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAcceptedFriends(userId: String) throws -> [FriendRelationship] {
        let descriptor = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate { r in
                (r.requesterId == userId || r.receiverId == userId) &&
                r.status == "accepted"
            }
        )
        return try context.fetch(descriptor)
    }

    func fetchPendingRequests(userId: String) throws -> [FriendRelationship] {
        let descriptor = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate { r in
                r.receiverId == userId && r.status == "pending"
            }
        )
        return try context.fetch(descriptor)
    }

    func acceptRequest(_ relationship: FriendRelationship) {
        relationship.status = .accepted
        relationship.updatedAt = Date()
    }

    func declineOrRemove(_ relationship: FriendRelationship) {
        context.delete(relationship)
    }

    func save() throws { try context.save() }
}
