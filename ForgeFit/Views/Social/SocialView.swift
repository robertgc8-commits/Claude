import SwiftUI

struct SocialView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Feed").tag(0)
                    Text("Friends").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().background(Color.ffBorder)

                Group {
                    if selectedTab == 0 {
                        FeedView()
                    } else {
                        FriendsView()
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
