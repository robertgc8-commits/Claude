import Foundation
import SwiftData

@MainActor
final class FeedRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchFeed(limit: Int = 50) throws -> [FeedItem] {
        var descriptor = FetchDescriptor<FeedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetchUnreadCount() throws -> Int {
        let descriptor = FetchDescriptor<FeedItem>(
            predicate: #Predicate { !$0.isRead && !$0.isMine }
        )
        return try context.fetchCount(descriptor)
    }

    func markAllRead() throws {
        let descriptor = FetchDescriptor<FeedItem>(
            predicate: #Predicate { !$0.isRead }
        )
        let items = try context.fetch(descriptor)
        items.forEach { $0.isRead = true }
        try context.save()
    }

    func createFeedItem(
        actorUserId: String,
        actorUsername: String,
        actorDisplayName: String,
        type: FeedItemType,
        title: String,
        body: String,
        isMine: Bool = false
    ) -> FeedItem {
        let item = FeedItem(
            actorUserId: actorUserId,
            actorUsername: actorUsername,
            actorDisplayName: actorDisplayName,
            itemType: type,
            title: title,
            body: body,
            isMine: isMine
        )
        context.insert(item)
        return item
    }

    func save() throws { try context.save() }
}
