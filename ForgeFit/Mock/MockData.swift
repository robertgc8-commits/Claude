import Foundation

/// Static mock data used for previews and development.
enum MockData {

    // MARK: - Friend Search (canonical list lives in MockSocialData inside SocialService.swift)

    // MARK: - Feed Items (mock)

    static func mockFeedItems(currentUserId: String) -> [FeedItem] {
        [
            FeedItem(
                actorUserId: "u002",
                actorUsername: "alexfit",
                actorDisplayName: "Alex Chen",
                itemType: .workoutCompleted,
                title: "Workout Completed",
                body: "Alex completed a chest workout",
                isMine: false
            ),
            FeedItem(
                actorUserId: "u003",
                actorUsername: "sarahruns",
                actorDisplayName: "Sarah Miller",
                itemType: .prAchieved,
                title: "New PR",
                body: "Sarah hit a new deadlift PR: 100kg!",
                isMine: false
            ),
            FeedItem(
                actorUserId: currentUserId,
                actorUsername: "me",
                actorDisplayName: "You",
                itemType: .streakMilestone,
                title: "Streak Milestone",
                body: "You've hit your weekly target 4 weeks in a row!",
                isMine: true
            ),
            FeedItem(
                actorUserId: "u004",
                actorUsername: "mike_lifts",
                actorDisplayName: "Mike Torres",
                itemType: .achievementUnlocked,
                title: "Achievement Unlocked",
                body: "Mike unlocked \"Never Skip Legs\"",
                isMine: false
            ),
        ]
    }

    // MARK: - Sample Exercise Names

    static let sampleExerciseNames: [String] = [
        "Bench Press", "Squat", "Deadlift", "Pull-Up",
        "Overhead Press", "Barbell Row", "Leg Press", "Dumbbell Curl"
    ]
}
