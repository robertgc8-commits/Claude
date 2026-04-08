import Foundation
import SwiftData

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var feedItems: [FeedItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var isRefreshing = false

    private var feedRepo: FeedRepository?
    private let syncService: SyncServiceProtocol
    private var userId: String = ""

    init(syncService: SyncServiceProtocol = MockSyncService()) {
        self.syncService = syncService
    }

    func configure(context: ModelContext, userId: String) {
        self.feedRepo = FeedRepository(context: context)
        self.userId = userId
    }

    func load() {
        guard let feedRepo = feedRepo else { return }
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
        guard let feedRepo = feedRepo else { return }
        try? feedRepo.markAllRead()
        unreadCount = 0
        load()
    }
}
