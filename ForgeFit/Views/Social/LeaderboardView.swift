import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = LeaderboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Type picker
                HStack {
                    Text(vm.weekStartLabel)
                        .font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
                    Spacer()
                    Picker("", selection: Binding(get: { vm.selectedType }, set: { vm.selectType($0) })) {
                        ForEach(LeaderboardType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .padding(.horizontal, 16)

                if vm.isLoading {
                    HStack { Spacer(); ProgressView().tint(Color.ffAccent); Spacer() }
                        .padding(.top, 60)
                } else if vm.entries.isEmpty {
                    emptyState
                } else {
                    podium
                    fullRankings
                }
            }
            .padding(.vertical, 12)
        }
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
    }

    // MARK: - Podium (top 3)

    @ViewBuilder
    private var podium: some View {
        let top = Array(vm.entries.prefix(3))
        if top.count >= 2 {
            HStack(alignment: .bottom, spacing: 8) {
                if top.count > 1 { podiumCell(top[1], height: 80, medalColor: Color(white: 0.7)) }
                if !top.isEmpty { podiumCell(top[0], height: 110, medalColor: Color.ffGold) }
                if top.count > 2 { podiumCell(top[2], height: 60, medalColor: Color.ffOrange) }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    }

    private func podiumCell(_ entry: LeaderboardEntry, height: CGFloat, medalColor: Color) -> some View {
        VStack(spacing: 6) {
            Circle().fill(entry.isCurrentUser ? Color.ffAccent : Color.ffSurface2)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(entry.displayName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(entry.isCurrentUser ? .white : Color.ffAccent)
                }
                .overlay(alignment: .topTrailing) {
                    Text(medalEmoji(entry.rank))
                        .font(.system(size: 14))
                        .offset(x: 4, y: -4)
                }

            Text(entry.isCurrentUser ? "You" : entry.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.ffText).lineLimit(1)

            Text(vm.formattedValue(entry.value))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(medalColor)

            RoundedRectangle(cornerRadius: 6)
                .fill(medalColor.opacity(0.25))
                .frame(height: height)
                .overlay {
                    Text("#\(entry.rank)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(medalColor)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func medalEmoji(_ rank: Int) -> String {
        switch rank { case 1: return "🥇"; case 2: return "🥈"; case 3: return "🥉"; default: return "" }
    }

    // MARK: - Full Rankings

    private var fullRankings: some View {
        VStack(spacing: 0) {
            ForEach(vm.entries) { entry in
                HStack(spacing: 14) {
                    Text("#\(entry.rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(entry.rank <= 3 ? Color.ffGold : Color.ffSubtext)
                        .frame(width: 28, alignment: .leading)

                    Circle().fill(entry.isCurrentUser ? Color.ffAccent : Color.ffSurface2)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text(entry.displayName.prefix(1).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(entry.isCurrentUser ? .white : Color.ffAccent)
                        }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.isCurrentUser ? "You" : entry.displayName)
                            .font(.system(size: 14, weight: entry.isCurrentUser ? .bold : .medium))
                            .foregroundStyle(Color.ffText)
                        Text("@" + entry.username)
                            .font(.system(size: 11)).foregroundStyle(Color.ffSubtext)
                    }

                    Spacer()

                    Text(vm.formattedValue(entry.value))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(entry.isCurrentUser ? Color.ffAccent : Color.ffText)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(entry.isCurrentUser ? Color.ffAccent.opacity(0.06) : Color.clear)

                Divider().background(Color.ffBorder).padding(.horizontal, 16)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3").font(.system(size: 44)).foregroundStyle(Color.ffBorder)
            Text("Add friends to see the leaderboard")
                .font(.system(size: 15)).foregroundStyle(Color.ffSubtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60).padding(.horizontal, 32)
    }
}
