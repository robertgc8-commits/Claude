import SwiftUI
import SwiftData

/// Utilities for SwiftUI Previews
enum PreviewHelpers {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            User.self, Workout.self, WorkoutExercise.self, ExerciseSet.self,
            ExerciseTemplate.self, PersonalRecord.self, AchievementUnlock.self,
            WeeklyStreakRecord.self, FriendRelationship.self, FeedItem.self, UserSettings.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }

    @MainActor
    static func populateContainer(_ container: ModelContainer) {
        let ctx = container.mainContext
        let userId = "preview_user"

        let user = User(id: userId, username: "previewuser", displayName: "Preview User", email: "preview@test.com")
        ctx.insert(user)

        let settings = UserSettings(userId: userId)
        ctx.insert(settings)
        user.settings = settings

        // Sample workouts
        for i in 0..<5 {
            let w = Workout(
                userId: userId,
                title: ["Push Day", "Pull Day", "Leg Day", "Upper Body", "Full Body"][i],
                startedAt: Date().addingTimeInterval(TimeInterval(-i * 86400 * 2))
            )
            w.complete()
            ctx.insert(w)

            let ex = WorkoutExercise(
                workoutId: w.id,
                exerciseName: ["Bench Press", "Deadlift", "Squat", "Pull-Up", "Overhead Press"][i],
                muscleGroup: [.chest, .back, .legs, .back, .shoulders][i],
                order: 0
            )
            ctx.insert(ex)

            for j in 0..<3 {
                let s = ExerciseSet(
                    workoutExerciseId: ex.id,
                    setNumber: j + 1,
                    reps: 8,
                    weight: Double(60 + j * 5)
                )
                s.isCompleted = true
                ctx.insert(s)
            }
        }

        try? ctx.save()
    }
}

// MARK: - Preview wrapper that wires up environment
struct PreviewContainer<Content: View>: View {
    @ViewBuilder let content: Content
    let container: ModelContainer
    let appState: AppState

    @MainActor init(@ViewBuilder content: () -> Content) {
        self.container = PreviewHelpers.makeContainer()
        self.appState = AppState()
        self.appState.currentUserId = "preview_user"
        self.appState.isAuthenticated = true
        self.appState.hasCompletedOnboarding = true
        self.content = content()
    }

    var body: some View {
        content
            .modelContainer(container)
            .environmentObject(appState)
            .preferredColorScheme(.dark)
    }
}
