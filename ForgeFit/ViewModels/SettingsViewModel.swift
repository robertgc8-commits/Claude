import Foundation
import SwiftData
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: UserSettings?
    @Published var isSaving = false

    private var userRepo: UserRepository?
    private let notificationService = NotificationService.shared
    private var userId: String = ""

    init() {}

    func configure(context: ModelContext, userId: String) {
        self.userRepo = UserRepository(context: context)
        self.userId = userId
    }

    func load() {
        guard let userRepo = userRepo else { return }
        settings = try? userRepo.fetchSettings(userId: userId)
    }

    func save() {
        guard let userRepo = userRepo else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try userRepo.save()
            applyNotificationSettings()
        } catch {
            print("Settings save error: \(error)")
        }
    }

    private func applyNotificationSettings() {
        guard let s = settings else { return }

        if s.receiveStreakReminders {
            // Will be rescheduled with correct remaining count by HomeViewModel
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
        }

        if !s.receiveInactivityReminders {
            notificationService.cancelInactivityReminder()
        }

        if s.receiveWeeklyReport {
            notificationService.scheduleWeeklyReport()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
        }
    }
}
