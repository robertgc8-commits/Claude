import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permissions

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Streak Reminders

    func scheduleStreakReminder(hour: Int, remaining: Int, target: Int) {
        let id = "streak_reminder"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard remaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep the streak alive"
        content.body = remaining == 1
            ? "One more workout this week to hit your goal."
            : "\(remaining) more workouts this week to hit your \(target)x goal."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Achievement Toast

    func scheduleAchievementNotification(title: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked"
        content.body = "\(title): \(description)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Inactivity Reminder

    func scheduleInactivityReminder(daysThreshold: Int) {
        let id = "inactivity_reminder"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Time to get back at it"
        content.body = "It's been a while. Your next workout is waiting."
        content.sound = .default

        let seconds = TimeInterval(daysThreshold * 86400)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelInactivityReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])
    }

    // MARK: - Weekly Summary

    func scheduleWeeklyReport() {
        let id = "weekly_report"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Your weekly summary is ready"
        content.body = "See how you did this week."
        content.sound = .default

        // Every Sunday at 8pm
        var comps = DateComponents()
        comps.weekday = 1  // Sunday
        comps.hour = 20
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
