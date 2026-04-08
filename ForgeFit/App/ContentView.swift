import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .overlay(alignment: .bottom) {
            AchievementToastOverlay()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingWorkoutSheet = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            WorkoutHistoryView()
                .tabItem { Label(AppTab.workout.title, systemImage: AppTab.workout.icon) }
                .tag(AppTab.workout)

            ProgressView()
                .tabItem { Label(AppTab.progress.title, systemImage: AppTab.progress.icon) }
                .tag(AppTab.progress)

            SocialView()
                .tabItem { Label(AppTab.social.title, systemImage: AppTab.social.icon) }
                .tag(AppTab.social)

            ProfileView()
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.icon) }
                .tag(AppTab.profile)
        }
        .tint(Color.ffAccent)
        .fullScreenCover(isPresented: $appState.showingActiveWorkout) {
            ActiveWorkoutView()
        }
    }
}
