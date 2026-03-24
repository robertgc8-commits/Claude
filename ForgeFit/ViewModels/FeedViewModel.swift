import Foundation
import SwiftData

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var feedItems: [FeedItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var isRefreshing = false

    private let feedRepo: FeedRepository
    private let syncService: SyncServiceProtocol
    private let userId: String

    init(context: ModelContext, userId: String, syncService: SyncServiceProtocol = MockSyncService()) {
        self.feedRepo = FeedRepository(context: context)
        self.syncService = syncService
        self.userId = userId
    }

    func load() {
        isLoading = true
        feedItems = (try? feedRepo.fetchFeed()) ?? []
        unreadCount = (try? feedRepo.fetchUnreadCount()) ?? 0
        isLoading = false
    }

    func refresh() {
        isRefreshing = true
        Task {
            try? await syncService.syncFeed(userId: userId)
            await MainActor.run {
                self.load()
                self.isRefreshing = false
            }
        }
    }

    func markAllRead() {
        try? feedRepo.markAllRead()
        unreadCount = 0
        load()
    }
}
