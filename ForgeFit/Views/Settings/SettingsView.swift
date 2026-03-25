import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: SettingsViewModel

    init() {
        _vm = StateObject(wrappedValue: SettingsViewModel(
            context: ModelContext(try! ModelContainer(for: UserSettings.self)),
            userId: ""
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let settings = vm.settings {
                    // Training goals
                    Section("Training Goal") {
                        Stepper(
                            "Weekly target: \(settings.weeklyWorkoutTarget)x",
                            value: Binding(
                                get: { settings.weeklyWorkoutTarget },
                                set: { settings.weeklyWorkoutTarget = $0; vm.save() }
                            ),
                            in: 2...7
                        )
                        .foregroundStyle(Color.ffText)

                        Picker("Weight Unit", selection: Binding(
                            get: { settings.preferredWeightUnit },
                            set: { settings.preferredWeightUnit = $0; vm.save() }
                        )) {
                            ForEach(WeightUnit.allCases, id: \.self) { Text($0.label).tag($0) }
                        }
                    }

                    // Visibility
                    Section {
                        Toggle("Discoverable Profile", isOn: Binding(
                            get: { settings.isProfileDiscoverable },
                            set: { settings.isProfileDiscoverable = $0; vm.save() }
                        ))
                        Picker("Who can view profile", selection: Binding(
                            get: { settings.profileVisibility },
                            set: { settings.profileVisibility = $0; vm.save() }
                        )) {
                            ForEach(ProfileVisibility.allCases, id: \.self) { Text($0.label).tag($0) }
                        }
                    } header: {
                        Text("Discoverability")
                    }

                    // What friends can see
                    Section {
                        Toggle("Workout titles", isOn: Binding(
                            get: { settings.shareWorkoutTitles },
                            set: { settings.shareWorkoutTitles = $0; vm.save() }
                        ))
                        Toggle("Exercise names", isOn: Binding(
                            get: { settings.shareExerciseNames },
                            set: { settings.shareExerciseNames = $0; vm.save() }
                        ))
                        Toggle("Sets, reps and weight", isOn: Binding(
                            get: { settings.shareSetsRepsWeight },
                            set: { settings.shareSetsRepsWeight = $0; vm.save() }
                        ))
                        Toggle("Personal records", isOn: Binding(
                            get: { settings.sharePRs },
                            set: { settings.sharePRs = $0; vm.save() }
                        ))
                        Toggle("Streaks", isOn: Binding(
                            get: { settings.shareStreaks },
                            set: { settings.shareStreaks = $0; vm.save() }
                        ))
                        Toggle("Achievements", isOn: Binding(
                            get: { settings.shareAchievements },
                            set: { settings.shareAchievements = $0; vm.save() }
                        ))
                    } header: {
                        Text("What friends can see")
                    } footer: {
                        Text("Friends only see what you allow. Changes apply immediately.")
                    }

                    // What friends are notified about
                    Section {
                        Toggle("When I complete a workout", isOn: Binding(
                            get: { settings.notifyFriendsOnWorkout },
                            set: { settings.notifyFriendsOnWorkout = $0; vm.save() }
                        ))
                        Toggle("When I hit a PR", isOn: Binding(
                            get: { settings.notifyFriendsOnPR },
                            set: { settings.notifyFriendsOnPR = $0; vm.save() }
                        ))
                        Toggle("When I hit a streak milestone", isOn: Binding(
                            get: { settings.notifyFriendsOnStreak },
                            set: { settings.notifyFriendsOnStreak = $0; vm.save() }
                        ))
                        Toggle("When I unlock an achievement", isOn: Binding(
                            get: { settings.notifyFriendsOnAchievement },
                            set: { settings.notifyFriendsOnAchievement = $0; vm.save() }
                        ))
                    } header: {
                        Text("Notify my friends")
                    }

                    // My notifications
                    Section {
                        Toggle("Streak reminders", isOn: Binding(
                            get: { settings.receiveStreakReminders },
                            set: { settings.receiveStreakReminders = $0; vm.save() }
                        ))
                        Toggle("Friend activity", isOn: Binding(
                            get: { settings.receiveFriendActivityNotifs },
                            set: { settings.receiveFriendActivityNotifs = $0; vm.save() }
                        ))
                        Toggle("Inactivity reminders", isOn: Binding(
                            get: { settings.receiveInactivityReminders },
                            set: { settings.receiveInactivityReminders = $0; vm.save() }
                        ))
                        Toggle("Weekly summary", isOn: Binding(
                            get: { settings.receiveWeeklyReport },
                            set: { settings.receiveWeeklyReport = $0; vm.save() }
                        ))
                    } header: {
                        Text("My notifications")
                    }

                    // Account
                    Section {
                        Button("Sign Out", role: .destructive) {
                            appState.signOut()
                        }
                    }
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
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
    }
}
