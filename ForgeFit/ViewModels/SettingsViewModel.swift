import Foundation
import SwiftData
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: UserSettings?
    @Published var isSaving = false
    @Published var csvExportURL: URL?
    @Published var isExporting = false

    private var userRepo: UserRepository?
    private var workoutRepo: WorkoutRepository?
    private let notificationService = NotificationService.shared
    private(set) var userId: String = ""

    init() {}

    func configure(context: ModelContext, userId: String) {
        self.userRepo = UserRepository(context: context)
        self.workoutRepo = WorkoutRepository(context: context)
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

    // MARK: - Notification Wiring

    private func applyNotificationSettings() {
        guard let s = settings else { return }
        let ns = NotificationService.shared

        if s.receiveStreakReminders {
            ns.scheduleStreakReminder(
                hour: s.streakReminderHour,
                remaining: 1,
                target: s.weeklyWorkoutTarget
            )
        } else {
            ns.cancelStreakReminder()
        }

        if s.receiveInactivityReminders {
            ns.scheduleInactivityReminder(daysThreshold: s.inactivityThresholdDays)
        } else {
            ns.cancelInactivityReminder()
        }

        if s.receiveWeeklyReport {
            ns.scheduleWeeklyReport()
        } else {
            ns.cancelWeeklyReport()
        }
    }

    // MARK: - CSV Export

    func generateCSV(workouts: [Workout]) -> String {
        var rows: [String] = [
            "Date,Workout Title,Exercise,Set,Reps,Weight (kg),RPE,Volume,Is Warmup,Is Drop Set,Duration (min)"
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for workout in workouts.filter({ $0.isCompleted }) {
            let dateStr = dateFormatter.string(from: workout.completedAt ?? workout.startedAt)
            let durationMin: String
            if let d = workout.durationSeconds {
                durationMin = String(format: "%.0f", Double(d) / 60.0)
            } else {
                durationMin = ""
            }
            let title = csvEscape(workout.title)

            let exercises = (workout.exercises ?? []).sorted { $0.order < $1.order }
            for exercise in exercises {
                let exerciseName = csvEscape(exercise.exerciseName)
                for set in exercise.completedSets {
                    let rpeStr = set.rpe.map { "\($0)" } ?? ""
                    let volume = set.weight * Double(set.reps)
                    let row = [
                        dateStr,
                        title,
                        exerciseName,
                        "\(set.setNumber)",
                        "\(set.reps)",
                        String(format: "%.2f", set.weight),
                        rpeStr,
                        String(format: "%.2f", volume),
                        "\(set.isWarmup)",
                        "\(set.isDropSet)",
                        durationMin
                    ].joined(separator: ",")
                    rows.append(row)
                }
            }
        }

        return rows.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    func exportURL(from csv: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ForgeFit_Workouts.csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV export write error: \(error)")
            return nil
        }
    }

    func prepareExport() {
        guard let workoutRepo else { return }
        isExporting = true
        defer { isExporting = false }
        let workouts = (try? workoutRepo.fetchAllWorkouts(userId: userId)) ?? []
        let csv = generateCSV(workouts: workouts)
        csvExportURL = exportURL(from: csv)
    }

    // MARK: - Account Deletion

    func deleteAccount(context: ModelContext, userId: String, appState: AppState) {
        deleteAll(Workout.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(PersonalRecord.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(WeeklyStreakRecord.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(AchievementUnlock.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(BodyWeightEntry.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(BodyMeasurementEntry.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(WorkoutTemplate.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(FeedItem.self,
                  predicate: #Predicate { $0.actorUserId == userId },
                  context: context)
        deleteAll(FriendRelationship.self,
                  predicate: #Predicate { $0.requesterId == userId || $0.receiverId == userId },
                  context: context)
        deleteAll(UserSettings.self,
                  predicate: #Predicate { $0.userId == userId },
                  context: context)
        deleteAll(User.self,
                  predicate: #Predicate { $0.id == userId },
                  context: context)

        try? context.save()

        // Stub: real backend deletion would be handled by SyncService
        Task {
            await MockSyncService().deleteAccount(userId: userId)
        }

        appState.signOut()
    }

    private func deleteAll<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>,
        context: ModelContext
    ) {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        let items = (try? context.fetch(descriptor)) ?? []
        items.forEach { context.delete($0) }
    }
}
