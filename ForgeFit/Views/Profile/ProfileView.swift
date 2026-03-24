import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext

    @Query private var users: [User]
    @Query private var workouts: [Workout]
    @Query private var unlocks: [AchievementUnlock]

    @State private var showingSettings = false
    @State private var showingAchievements = false

    private var currentUser: User? { users.first { $0.id == appState.currentUserId } }
    private var completedWorkouts: [Workout] { workouts.filter { $0.isCompleted && $0.userId == appState.currentUserId } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats
                    statsSection

                    // Quick navigation
                    quickLinks
                }
                .padding(.vertical, 12)
            }
            .background(Color.ffBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.ffSubtext)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(colors: [Color.ffAccent, Color.ffAccent.opacity(0.5)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Text((currentUser?.displayName ?? "U").prefix(1).uppercased())
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)
                }

            VStack(spacing: 4) {
                Text(currentUser?.displayName ?? "ForgeFit User")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.ffText)
                if let username = currentUser?.username {
                    Text("@" + username)
                        .font(.system(size: 14)).foregroundStyle(Color.ffSubtext)
                }
            }

            Text("Member since " + (currentUser?.createdAt.workoutDateDisplay() ?? ""))
                .font(.system(size: 12))
                .foregroundStyle(Color.ffSubtext)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(completedWorkouts.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Color.ffText)
                Text("Workouts").font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).ffCard()

            VStack(spacing: 4) {
                Text("\(unlocks.filter { $0.userId == appState.currentUserId }.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Color.ffText)
                Text("Achievements").font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).ffCard()

            VStack(spacing: 4) {
                let vol = completedWorkouts.reduce(0.0) { $0 + $1.totalVolume }
                Text(vol.volumeDisplay())
                    .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Color.ffText)
                Text("Total kg").font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).ffCard()
        }
        .padding(.horizontal, 16)
    }

    private var quickLinks: some View {
        VStack(spacing: 0) {
            profileLink(icon: "trophy.fill", color: .ffGold, title: "Achievements") {
                showingAchievements = true
            }
            Divider().background(Color.ffBorder).padding(.horizontal, 16)
            profileLink(icon: "chart.line.uptrend.xyaxis", color: .ffAccent, title: "Progress") {
                appState.selectedTab = .progress
            }
            Divider().background(Color.ffBorder).padding(.horizontal, 16)
            profileLink(icon: "gearshape.fill", color: .ffSubtext, title: "Settings") {
                showingSettings = true
            }
        }
        .background(Color.ffSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func profileLink(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
                    .frame(width: 32)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.ffText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffBorder)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
