import SwiftUI

struct SocialView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented tab picker
                Picker("", selection: $selectedTab) {
                    Text("Feed").tag(0)
                    Text("Friends").tag(1)
                    Text("Board").tag(2)
                    Text("Challenges").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().background(Color.ffBorder)

                Group {
                    switch selectedTab {
                    case 0: FeedView()
                    case 1: FriendsView()
                    case 2: LeaderboardView()
                    default: ChallengesView()
                    }
                }
            }
            .background(Color.ffBackground)
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}
