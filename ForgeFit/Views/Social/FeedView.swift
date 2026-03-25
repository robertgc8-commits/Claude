import SwiftUI
import SwiftData

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm: FeedViewModel

    init() {
        _vm = StateObject(wrappedValue: FeedViewModel(
            context: ModelContext(try! ModelContainer(for: FeedItem.self)),
            userId: ""
        ))
    }

    var body: some View {
        Group {
            if vm.feedItems.isEmpty && !vm.isLoading {
                emptyFeed
            } else {
                feedList
            }
        }
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
            vm.markAllRead()
        }
        .refreshable { vm.refresh() }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.feedItems) { item in
                    FeedItemRow(item: item)
                    Divider().background(Color.ffBorder)
                }
            }
        }
    }

    private var emptyFeed: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 52)).foregroundStyle(Color.ffBorder)
            Text("Nothing here yet")
                .font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.ffSubtext)
            Text("Add friends to see their workout activity")
                .font(.system(size: 14)).foregroundStyle(Color.ffSubtext.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Feed Item Row
struct FeedItemRow: View {
    let item: FeedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.ffSurface2)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(item.actorDisplayName.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.ffAccent)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.actorDisplayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ffText)
                    Image(systemName: item.typeIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(feedItemColor(item.itemType))
                }
                Text(item.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ffSubtext)
            }

            Spacer()

            Text(item.createdAt.relativeDisplay())
                .font(.system(size: 11))
                .foregroundStyle(Color.ffSubtext)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(item.isRead ? Color.clear : Color.ffAccent.opacity(0.04))
    }

    private func feedItemColor(_ type: FeedItemType) -> Color {
        switch type {
        case .workoutCompleted: return .ffGreen
        case .prAchieved: return .ffGold
        case .streakMilestone: return .ffOrange
        case .achievementUnlocked: return .ffAccent
        }
    }
}
