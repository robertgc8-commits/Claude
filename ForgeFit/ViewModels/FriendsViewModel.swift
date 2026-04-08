import Foundation
import SwiftData

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendRelationship] = []
    @Published var pendingRequests: [FriendRelationship] = []
    @Published var searchResults: [UserSearchResult] = []
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedProfile: PublicProfile?
    @Published var isLoadingProfile = false

    private var friendRepo: FriendRepository?
    private var context: ModelContext?
    private var userId: String = ""
    private let socialService: SocialServiceProtocol

    init(socialService: SocialServiceProtocol = SocialServiceProvider.shared) {
        self.socialService = socialService
    }

    func configure(context: ModelContext, userId: String) {
        self.context = context
        self.userId = userId
        self.friendRepo = FriendRepository(context: context)
    }

    func load() {
        guard let friendRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try friendRepo.fetchAcceptedFriends(userId: userId)
            pendingRequests = try friendRepo.fetchPendingRequests(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - User Search

    func searchUsers() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { searchResults = []; return }
        isSearching = true
        Task {
            do {
                let alreadyFriendIds = Set(friends.map { $0.friendUserId })
                let pendingIds = Set(pendingRequests.map { $0.friendUserId })
                var results = try await socialService.searchUsers(query: query, currentUserId: userId)
                // Annotate results with local relationship state
                results = results.map { r in
                    UserSearchResult(
                        id: r.id,
                        username: r.username,
                        displayName: r.displayName,
                        avatarURL: r.avatarURL,
                        workoutCount: r.workoutCount,
                        isAlreadyFriend: alreadyFriendIds.contains(r.id),
                        hasPendingRequest: pendingIds.contains(r.id)
                    )
                }
                self.searchResults = results
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isSearching = false
        }
    }

    // MARK: - Friend Actions

    func sendRequest(to result: UserSearchResult) {
        guard let context, let friendRepo else { return }
        let relationship = FriendRelationship(
            requesterId: userId,
            receiverId: result.id,
            friendUserId: result.id,
            friendUsername: result.username,
            friendDisplayName: result.displayName,
            friendAvatarURL: result.avatarURL,
            status: .pending
        )
        context.insert(relationship)
        try? friendRepo.save()
        // Notify backend
        Task { try? await socialService.sendFriendRequest(fromUserId: userId, toUserId: result.id) }
        load()
        // Refresh search results to reflect new pending state
        searchUsers()
    }

    func acceptRequest(_ relationship: FriendRelationship) {
        guard let friendRepo else { return }
        friendRepo.acceptRequest(relationship)
        try? friendRepo.save()
        Task { try? await socialService.acceptFriendRequest(relationshipId: relationship.id, userId: userId) }
        load()
    }

    func declineRequest(_ relationship: FriendRelationship) {
        guard let friendRepo else { return }
        friendRepo.declineOrRemove(relationship)
        try? friendRepo.save()
        Task { try? await socialService.declineFriendRequest(relationshipId: relationship.id, userId: userId) }
        load()
    }

    func removeFriend(_ relationship: FriendRelationship) {
        guard let friendRepo else { return }
        friendRepo.declineOrRemove(relationship)
        try? friendRepo.save()
        Task { try? await socialService.removeFriend(relationshipId: relationship.id, userId: userId) }
        load()
    }

    // MARK: - Privacy-Filtered Profile

    func loadProfile(for friend: FriendRelationship) {
        isLoadingProfile = true
        selectedProfile = nil
        Task {
            do {
                self.selectedProfile = try await socialService.fetchPublicProfile(
                    userId: friend.friendUserId,
                    viewerUserId: userId
                )
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoadingProfile = false
        }
    }
}
