import Foundation
import SwiftData

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendRelationship] = []
    @Published var pendingRequests: [FriendRelationship] = []
    @Published var searchResults: [MockFriendSearchResult] = []
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var friendRepo: FriendRepository?
    private var context: ModelContext?
    private var userId: String = ""

    init() {}

    func configure(context: ModelContext, userId: String) {
        self.context = context
        self.userId = userId
        self.friendRepo = FriendRepository(context: context)
    }

    func load() {
        guard let friendRepo = friendRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try friendRepo.fetchAcceptedFriends(userId: userId)
            pendingRequests = try friendRepo.fetchPendingRequests(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchUsers() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        // Mock search results
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                self.searchResults = MockData.friendSearchResults
                    .filter { $0.username.localizedCaseInsensitiveContains(self.searchText) }
                self.isSearching = false
            }
        }
    }

    func sendRequest(to result: MockFriendSearchResult) {
        guard let context = context, let friendRepo = friendRepo else { return }
        let relationship = FriendRelationship(
            requesterId: userId,
            receiverId: result.id,
            friendUserId: result.id,
            friendUsername: result.username,
            friendDisplayName: result.displayName,
            friendAvatarURL: nil,
            status: .pending
        )
        context.insert(relationship)
        try? friendRepo.save()
        load()
    }

    func acceptRequest(_ relationship: FriendRelationship) {
        guard let friendRepo = friendRepo else { return }
        friendRepo.acceptRequest(relationship)
        try? friendRepo.save()
        load()
    }

    func declineRequest(_ relationship: FriendRelationship) {
        guard let friendRepo = friendRepo else { return }
        friendRepo.declineOrRemove(relationship)
        try? friendRepo.save()
        load()
    }

    func removeFriend(_ relationship: FriendRelationship) {
        guard let friendRepo = friendRepo else { return }
        friendRepo.declineOrRemove(relationship)
        try? friendRepo.save()
        load()
    }
}

struct MockFriendSearchResult: Identifiable {
    let id: String
    let username: String
    let displayName: String
    let workoutCount: Int
}
