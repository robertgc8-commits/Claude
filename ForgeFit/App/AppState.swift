import SwiftUI
import Combine

enum AppTab: Int, CaseIterable {
    case home, workout, progress, social, profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .workout: return "Log"
        case .progress: return "Progress"
        case .social: return "Social"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .workout: return "plus.circle.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .social: return "person.2.fill"
        case .profile: return "person.circle.fill"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUserId: String = ""
    @Published var showingActiveWorkout: Bool = false
    @Published var pendingAchievements: [AchievementDefinition] = []

    init() {
        // Load persisted auth state
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
    }

    func signIn(userId: String) {
        currentUserId = userId
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(userId, forKey: "currentUserId")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func skipToApp() {
        let guestId = "guest_\(UUID().uuidString.prefix(8))"
        signIn(userId: guestId)
        completeOnboarding()
    }

    func signOut() {
        currentUserId = ""
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func queueAchievement(_ achievement: AchievementDefinition) {
        DispatchQueue.main.async {
            self.pendingAchievements.append(achievement)
        }
    }

    func dequeueAchievement() -> AchievementDefinition? {
        guard !pendingAchievements.isEmpty else { return nil }
        return pendingAchievements.removeFirst()
    }
}
