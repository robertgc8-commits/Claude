import SwiftUI
import SwiftData
import UserNotifications

@main
struct ForgeFitApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Workout.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            ExerciseTemplate.self,
            PersonalRecord.self,
            AchievementUnlock.self,
            WeeklyStreakRecord.self,
            FriendRelationship.self,
            FeedItem.self,
            UserSettings.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    appState.requestNotificationPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
