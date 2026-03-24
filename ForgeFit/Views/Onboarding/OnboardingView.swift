import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm: OnboardingViewModel

    init() {
        // Placeholder — real init uses environment modelContext in body
        _vm = StateObject(wrappedValue: OnboardingViewModel(context: OnboardingViewModel.placeholderContext))
    }

    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()

            switch vm.currentStep {
            case .welcome:       WelcomeStep(vm: vm)
            case .createAccount: CreateAccountStep(vm: vm)
            case .setGoal:       SetGoalStep(vm: vm)
            case .permissions:   PermissionsStep(vm: vm)
            case .done:          OnboardingDoneStep { appState.completeOnboarding() }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Welcome Step
private struct WelcomeStep: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.ffAccent)

                Text("ForgeFit")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Color.ffText)

                Text("Track your lifts.\nBuild the habit.\nSee the progress.")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.ffSubtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
            FFButton(title: "Get Started", style: .primary) {
                vm.advance()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Create Account
private struct CreateAccountStep: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingHeader(title: vm.currentStep.title, step: 1, total: 4)

                VStack(spacing: 14) {
                    FFTextField(placeholder: "Display Name", text: $vm.displayName)
                    FFTextField(placeholder: "Username", text: $vm.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    FFTextField(placeholder: "Email", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    FFTextField(placeholder: "Password", text: $vm.password, isSecure: true)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ffRed)
                        .multilineTextAlignment(.center)
                }

                FFButton(title: "Create Account", style: .primary, isLoading: vm.isCreatingAccount) {
                    vm.createAccount()
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Set Goal
private struct SetGoalStep: View {
    @ObservedObject var vm: OnboardingViewModel
    private let targets = [2, 3, 4, 5, 6]

    var body: some View {
        VStack(spacing: 32) {
            OnboardingHeader(title: vm.currentStep.title, step: 2, total: 4)
                .padding(.horizontal, 24)

            Text("How many times per week do you want to work out?")
                .font(.system(size: 17))
                .foregroundStyle(Color.ffSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 12) {
                ForEach(targets, id: \.self) { n in
                    Button {
                        HapticFeedback.impact(.light)
                        vm.weeklyTarget = n
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(n)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                            Text("x / week")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(vm.weeklyTarget == n ? Color.white : Color.ffSubtext)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(vm.weeklyTarget == n ? Color.ffAccent : Color.ffSurface)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Text("A streak is maintained each week you hit this target.")
                .font(.system(size: 13))
                .foregroundStyle(Color.ffSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            FFButton(title: "Continue", style: .primary) { vm.saveGoal() }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Permissions
private struct PermissionsStep: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            OnboardingHeader(title: vm.currentStep.title, step: 3, total: 4)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                permissionRow(icon: "bell.fill", color: .ffAccent,
                    title: "Streak reminders",
                    detail: "Get nudged when you\'re close to hitting your weekly goal.")
                permissionRow(icon: "person.2.fill", color: .ffPurple,
                    title: "Friend activity",
                    detail: "Know when your friends log a workout or hit a PR.")
                permissionRow(icon: "chart.bar.fill", color: .ffGreen,
                    title: "Weekly summary",
                    detail: "See your weekly stats every Sunday.")
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                FFButton(title: "Enable Notifications", style: .primary) {
                    vm.requestNotifications()
                }
                Button("Not Now") { vm.skipNotifications() }
                    .font(.system(size: 15))
                    .foregroundStyle(Color.ffSubtext)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func permissionRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ffText)
                Text(detail).font(.system(size: 13)).foregroundStyle(Color.ffSubtext)
            }
        }
        .padding(14)
        .ffCard()
    }
}

// MARK: - Done
private struct OnboardingDoneStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.ffGreen)
            Text("You're ready")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(Color.ffText)
            Text("Start logging your first workout\nand watch your progress build.")
                .font(.system(size: 17))
                .foregroundStyle(Color.ffSubtext)
                .multilineTextAlignment(.center)
            Spacer()
            FFButton(title: "Start Training", style: .primary) { onFinish() }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Shared Components
private struct OnboardingHeader: View {
    let title: String
    let step: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.ffAccent : Color.ffBorder)
                        .frame(height: 3)
                }
            }
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.ffText)
        }
    }
}

extension OnboardingViewModel {
    static var placeholderContext: ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: User.self, configurations: config)
        return ModelContext(container)
    }
}
