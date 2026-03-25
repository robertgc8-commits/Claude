import SwiftUI
import SwiftData

struct FriendsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = FriendsViewModel()
    @State private var showingSearch = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !vm.pendingRequests.isEmpty { pendingSection }
                if vm.friends.isEmpty { emptyFriends } else { friendsList }
            }
            .padding(.vertical, 12)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSearch = true
                } label: {
                    Image(systemName: "person.badge.plus").foregroundStyle(Color.ffAccent)
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            FriendSearchView(vm: vm)
        }
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
    }

    // MARK: - Pending

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Friend Requests").ffSectionHeader().padding(.horizontal, 16)
            ForEach(vm.pendingRequests) { request in
                HStack(spacing: 12) {
                    avatarCircle(request.friendDisplayName)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.friendDisplayName)
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ffText)
                        Text("@" + request.friendUsername)
                            .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                    }
                    Spacer()
                    Button("Accept") { vm.acceptRequest(request) }
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.ffAccent).clipShape(Capsule())
                    Button("Decline") { vm.declineRequest(request) }
                        .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
        }
    }

    // MARK: - Friends List

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Friends (\(vm.friends.count))")
                .ffSectionHeader().padding(.horizontal, 16).padding(.bottom, 10)
            ForEach(vm.friends) { friend in
                NavigationLink {
                    FriendProfileView(
                        friend: friend,
                        onRemove: { vm.removeFriend(friend) }
                    )
                    .onAppear { vm.loadProfile(for: friend) }
                    .environmentObject(vm)
                } label: {
                    HStack(spacing: 12) {
                        avatarCircle(friend.friendDisplayName)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.friendDisplayName)
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ffText)
                            Text("@" + friend.friendUsername)
                                .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12)).foregroundStyle(Color.ffBorder)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                Divider().background(Color.ffBorder).padding(.horizontal, 16)
            }
        }
    }

    private var emptyFriends: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2").font(.system(size: 44)).foregroundStyle(Color.ffBorder)
            Text("No friends yet").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.ffSubtext)
            Button { showingSearch = true } label: {
                Text("Find Friends").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffAccent)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 48)
    }

    private func avatarCircle(_ name: String) -> some View {
        Circle().fill(Color.ffSurface2).frame(width: 44, height: 44)
            .overlay {
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Color.ffAccent)
            }
    }
}

// MARK: - Friend Search

struct FriendSearchView: View {
    @ObservedObject var vm: FriendsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.isSearching {
                    ProgressView().tint(Color.ffAccent).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !vm.searchResults.isEmpty {
                    List(vm.searchResults) { result in
                        searchRow(result)
                            .listRowBackground(Color.ffSurface)
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                } else if !vm.searchText.isEmpty {
                    Text("No users found").foregroundStyle(Color.ffSubtext)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Search by username").foregroundStyle(Color.ffSubtext)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.ffBackground)
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.ffAccent)
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search by username")
            .onChange(of: vm.searchText) { vm.searchUsers() }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func searchRow(_ result: UserSearchResult) -> some View {
        HStack {
            Circle().fill(Color.ffSurface2).frame(width: 40, height: 40)
                .overlay {
                    Text(result.displayName.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Color.ffAccent)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(result.displayName)
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.ffText)
                Text("@" + result.username)
                    .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            }
            Spacer()
            if result.isAlreadyFriend {
                Text("Friends")
                    .font(.system(size: 12)).foregroundStyle(Color.ffGreen)
            } else if result.hasPendingRequest {
                Text("Pending")
                    .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            } else {
                Button("Add") { vm.sendRequest(to: result) }
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.ffAccent).clipShape(Capsule())
            }
        }
    }
}

// MARK: - Friend Profile

struct FriendProfileView: View {
    let friend: FriendRelationship
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: FriendsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar
                Circle().fill(Color.ffSurface2).frame(width: 80, height: 80)
                    .overlay {
                        Text(friend.friendDisplayName.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .bold)).foregroundStyle(Color.ffAccent)
                    }
                VStack(spacing: 4) {
                    Text(friend.friendDisplayName)
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.ffText)
                    Text("@" + friend.friendUsername)
                        .font(.system(size: 14)).foregroundStyle(Color.ffSubtext)
                }

                // Privacy-filtered stats
                if vm.isLoadingProfile {
                    ProgressView().tint(Color.ffAccent).padding(.top, 8)
                } else if let profile = vm.selectedProfile {
                    profileStats(profile)
                }

                // Remove
                Button("Remove Friend") { onRemove(); dismiss() }
                    .font(.system(size: 14)).foregroundStyle(Color.ffRed).padding(.top, 8)
            }
            .padding(.top, 24).padding(.horizontal, 16)
        }
        .background(Color.ffBackground)
        .navigationTitle(friend.friendDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func profileStats(_ profile: PublicProfile) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let v = profile.weeklyWorkouts {
                profileStat("\(v)", label: "This Week")
            }
            if let v = profile.currentStreak {
                profileStat("\(v)w", label: "Streak")
            }
            if let v = profile.totalWorkouts {
                profileStat("\(v)", label: "Total Workouts")
            }
            if let v = profile.recentPRLabel {
                profileStat(v, label: "Recent PR")
            }
        }
    }

    private func profileStat(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ffText).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).ffCard()
    }
}
