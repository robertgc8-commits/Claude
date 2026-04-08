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

    /// Schedules a daily repeating reminder at `hour`:00.
    /// `remaining` = workouts still needed this week; `target` = weekly goal.
    /// Cancels any existing streak reminder first.
    func scheduleStreakReminder(hour: Int, remaining: Int, target: Int) {
        let id = "streak_reminder"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard remaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep the streak alive"
        content.body = remaining == 1
            ? "One more workout this week to hit your \(target)x goal."
            : "\(remaining) more workouts this week to hit your \(target)x goal."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = max(0, min(23, hour))
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelStreakReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
    }

    // MARK: - Inactivity Reminder

    /// Schedules a one-shot inactivity reminder relative to the last workout date.
    /// Fires at `lastWorkoutDate + thresholdDays`.  If that moment is already past,
    /// fires within 60 seconds (user is already overdue).  Calling this again after
    /// each completed workout correctly resets the countdown.
    func rescheduleInactivityReminder(from lastWorkoutDate: Date, thresholdDays: Int) {
        let id = "inactivity_reminder"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let fireDate = lastWorkoutDate.addingTimeInterval(TimeInterval(thresholdDays) * 86400)
        let interval = max(60, fireDate.timeIntervalSinceNow)

        let content = UNMutableNotificationContent()
        content.title = "Time to get back at it"
        content.body = "It's been \(thresholdDays)+ days since your last workout. You've got this."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelInactivityReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])
    }

    // MARK: - Weekly Summary

    /// Schedules a repeating weekly summary every Sunday at 20:00 local time.
    func scheduleWeeklyReport() {
        let id = "weekly_report"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Your weekly summary is ready"
        content.body = "See how you did this week."
        content.sound = .default

        var comps = DateComponents()
        comps.weekday = 1  // Sunday
        comps.hour = 20
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelWeeklyReport() {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
    }

    // MARK: - Achievement Toast

    func scheduleAchievementNotification(title: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked"
        content.body = "\(title): \(description)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        ))
    }
}
