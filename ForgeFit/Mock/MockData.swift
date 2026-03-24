import Foundation

/// Static mock data used for previews and development.
enum MockData {

    // MARK: - Friend Search

    static let friendSearchResults: [MockFriendSearchResult] = [
        MockFriendSearchResult(id: "u002", username: "alexfit", displayName: "Alex Chen", workoutCount: 87),
        MockFriendSearchResult(id: "u003", username: "sarahruns", displayName: "Sarah Miller", workoutCount: 124),
        MockFriendSearchResult(id: "u004", username: "mike_lifts", displayName: "Mike Torres", workoutCount: 42),
        MockFriendSearchResult(id: "u005", username: "kettlebell_queen", displayName: "Jordan Lee", workoutCount: 201),
        MockFriendSearchResult(id: "u006", username: "benchpressking", displayName: "Chris Park", workoutCount: 63),
    ]

    // MARK: - Feed Items (mock)

    static func mockFeedItems(currentUserId: String) -> [FeedItem] [
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

    // MARK: - Sample Exercise Templates

    static let sampleExerciseNames: [String] = [
        "Bench Press", "Squat", "Deadlift", "Pull-Up",
        "Overhead Press", "Barbell Row", "Leg Press", "Dumbbell Curl"
    ]
}
