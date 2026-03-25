import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SettingsViewModel()

    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                if let settings = vm.settings {
                    trainingSection(settings)
                    workoutBehaviourSection(settings)
                    discoverabilitySection(settings)
                    friendSharingSection(settings)
                    friendNotificationsSection(settings)
                    myNotificationsSection(settings)
                    dataSection
                    accountSection
                } else {
                    Section {
                        Text("Loading settings…")
                            .foregroundStyle(Color.ffSubtext)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ffBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ffAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Delete Account",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                vm.deleteAccount(context: modelContext, userId: appState.currentUserId, appState: appState)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all your workouts, records, body weight logs, and settings. This cannot be undone.")
        }
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
    }

    // MARK: - Training Goal

    private func trainingSection(_ s: UserSettings) -> some View {
        Section("Training Goal") {
            Stepper(
                "Weekly target: \(s.weeklyWorkoutTarget)x",
                value: Binding(
                    get: { s.weeklyWorkoutTarget },
                    set: { s.weeklyWorkoutTarget = $0; vm.save() }
                ),
                in: 2...7
            )
            .foregroundStyle(Color.ffText)

            Picker("Weight Unit", selection: Binding(
                get: { s.preferredWeightUnit },
                set: { s.preferredWeightUnit = $0; vm.save() }
            )) {
                ForEach(WeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
            }
        }
        .listRowBackground(Color.ffSurface)
    }

    // MARK: - Workout Behaviour

    private func workoutBehaviourSection(_ s: UserSettings) -> some View {
        Section {
            // Rest timer: 30–300 s in 15 s steps
            Stepper(
                "Rest timer: \(formatSeconds(s.restTimerDuration))",
                value: Binding(
                    get: { s.restTimerDuration },
                    set: { s.restTimerDuration = $0; vm.save() }
                ),
                in: 30...300,
                step: 15
            )
            .foregroundStyle(Color.ffText)

            // Weight increment
            Picker("Weight increment", selection: Binding(
                get: { s.defaultWeightIncrement },
                set: { s.defaultWeightIncrement = $0; vm.save() }
            )) {
                ForEach(weightIncrementOptions(unit: s.preferredWeightUnit), id: \.self) { v in
                    Text(formatIncrement(v, unit: s.preferredWeightUnit)).tag(v)
                }
            }
        } header: {
            Text("Workout Behaviour")
        } footer: {
            Text("Rest timer and increment apply to new sets in every workout.")
        }
        .listRowBackground(Color.ffSurface)
    }

    private func weightIncrementOptions(unit: WeightUnit) -> [Double] {
        unit == .kg ? [0.5, 1.0, 1.25, 2.5, 5.0] : [1.0, 2.5, 5.0, 10.0]
    }

    private func formatIncrement(_ v: Double, unit: WeightUnit) -> String {
        let s = v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.2f", v).replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return "\(s) \(unit.label)"
    }

    private func formatSeconds(_ s: Int) -> String {
        if s < 60 { return "\(s)s" }
        let m = s / 60
        let rem = s % 60
        return rem == 0 ? "\(m)m" : "\(m)m \(rem)s"
    }

    // MARK: - Discoverability

    private func discoverabilitySection(_ s: UserSettings) -> some View {
        Section {
            Toggle("Discoverable Profile", isOn: Binding(
                get: { s.isProfileDiscoverable },
                set: { s.isProfileDiscoverable = $0; vm.save() }
            ))
            .tint(Color.ffAccent)
            Picker("Who can view profile", selection: Binding(
                get: { s.profileVisibility },
                set: { s.profileVisibility = $0; vm.save() }
            )) {
                ForEach(ProfileVisibility.allCases, id: \.self) { Text($0.label).tag($0) }
            }
        } header: {
            Text("Discoverability")
        }
        .listRowBackground(Color.ffSurface)
    }

    // MARK: - Friend Sharing

    private func friendSharingSection(_ s: UserSettings) -> some View {
        Section {
            Toggle("Workout titles", isOn: Binding(get: { s.shareWorkoutTitles },   set: { s.shareWorkoutTitles = $0;   vm.save() })).tint(Color.ffAccent)
            Toggle("Exercise names", isOn: Binding(get: { s.shareExerciseNames },   set: { s.shareExerciseNames = $0;   vm.save() })).tint(Color.ffAccent)
            Toggle("Sets, reps and weight", isOn: Binding(get: { s.shareSetsRepsWeight }, set: { s.shareSetsRepsWeight = $0; vm.save() })).tint(Color.ffAccent)
            Toggle("Personal records", isOn: Binding(get: { s.sharePRs },           set: { s.sharePRs = $0;           vm.save() })).tint(Color.ffAccent)
            Toggle("Streaks",          isOn: Binding(get: { s.shareStreaks },        set: { s.shareStreaks = $0;        vm.save() })).tint(Color.ffAccent)
            Toggle("Achievements",     isOn: Binding(get: { s.shareAchievements },  set: { s.shareAchievements = $0;  vm.save() })).tint(Color.ffAccent)
        } header: {
            Text("What friends can see")
        } footer: {
            Text("Friends only see what you allow. Changes apply immediately.")
        }
        .listRowBackground(Color.ffSurface)
    }

    // MARK: - Friend Notifications

    private func friendNotificationsSection(_ s: UserSettings) -> some View {
        Section {
            Toggle("When I complete a workout",       isOn: Binding(get: { s.notifyFriendsOnWorkout },     set: { s.notifyFriendsOnWorkout = $0;     vm.save() })).tint(Color.ffAccent)
            Toggle("When I hit a PR",                 isOn: Binding(get: { s.notifyFriendsOnPR },          set: { s.notifyFriendsOnPR = $0;          vm.save() })).tint(Color.ffAccent)
            Toggle("When I hit a streak milestone",   isOn: Binding(get: { s.notifyFriendsOnStreak },      set: { s.notifyFriendsOnStreak = $0;      vm.save() })).tint(Color.ffAccent)
            Toggle("When I unlock an achievement",    isOn: Binding(get: { s.notifyFriendsOnAchievement }, set: { s.notifyFriendsOnAchievement = $0; vm.save() })).tint(Color.ffAccent)
        } header: {
            Text("Notify my friends")
        }
        .listRowBackground(Color.ffSurface)
    }

    // MARK: - My Notifications

    private func myNotificationsSection(_ s: UserSettings) -> some View {
        Section {
            // Streak reminder toggle + time picker
            Toggle("Streak reminders", isOn: Binding(
                get: { s.receiveStreakReminders },
                set: { s.receiveStreakReminders = $0; vm.save() }
            ))
            .tint(Color.ffAccent)

            if s.receiveStreakReminders {
                Picker("Reminder time", selection: Binding(
                    get: { s.streakReminderHour },
                    set: { s.streakReminderHour = $0; vm.save() }
                )) {
                    ForEach(reminderHourOptions, id: \.hour) { opt in
                        Text(opt.label).tag(opt.hour)
                    }
                }
            }

            // Inactivity reminder toggle + threshold stepper
            Toggle("Inactivity reminders", isOn: Binding(
                get: { s.receiveInactivityReminders },
                set: { s.receiveInactivityReminders = $0; vm.save() }
            ))
            .tint(Color.ffAccent)

            if s.receiveInactivityReminders {
                Stepper(
                    "After \(s.inactivityThresholdDays) day\(s.inactivityThresholdDays == 1 ? "" : "s") off",
                    value: Binding(
                        get: { s.inactivityThresholdDays },
                        set: { s.inactivityThresholdDays = $0; vm.save() }
                    ),
                    in: 1...14
                )
                .foregroundStyle(Color.ffText)
            }

            Toggle("Friend activity",  isOn: Binding(get: { s.receiveFriendActivityNotifs }, set: { s.receiveFriendActivityNotifs = $0; vm.save() })).tint(Color.ffAccent)
            Toggle("Weekly summary",   isOn: Binding(get: { s.receiveWeeklyReport },          set: { s.receiveWeeklyReport = $0;          vm.save() })).tint(Color.ffAccent)
        } header: {
            Text("My Notifications")
        } footer: {
            Text("Streak reminders fire daily at the selected time while workouts remain for the week.")
        }
        .listRowBackground(Color.ffSurface)
    }

    private struct HourOption { let hour: Int; let label: String }
    private var reminderHourOptions: [HourOption] {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:00 a"
        return (0..<24).map { h in
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = h; comps.minute = 0
            let date = Calendar.current.date(from: comps) ?? Date()
            return HourOption(hour: h, label: fmt.string(from: date))
        }
    }

    // MARK: - Data / Export

    private var dataSection: some View {
        Section {
            if let url = vm.csvExportURL {
                ShareLink(
                    item: url,
                    subject: Text("ForgeFit Workout Data"),
                    message: Text("My complete workout history from ForgeFit")
                ) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Color.ffAccent)
                }
            } else {
                Button {
                    vm.prepareExport()
                } label: {
                    if vm.isExporting {
                        Label("Preparing export…", systemImage: "arrow.down.doc")
                            .foregroundStyle(Color.ffSubtext)
                    } else {
                        Label("Export Workout Data (.csv)", systemImage: "arrow.down.doc")
                            .foregroundStyle(Color.ffAccent)
                    }
                }
                .disabled(vm.isExporting)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Exports all completed workouts: date, exercise, sets, reps, weight, RPE, and volume.")
        }
        .listRowBackground(Color.ffSurface)
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            Button("Sign Out", role: .destructive) {
                appState.signOut()
            }
            Button("Delete Account", role: .destructive) {
                showingDeleteConfirm = true
            }
        }
        .listRowBackground(Color.ffSurface)
    }
}
