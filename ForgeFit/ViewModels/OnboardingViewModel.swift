import Foundation
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var weeklyTarget: Int = 4
    @Published var weightUnit: WeightUnit = .kg
    @Published var isCreatingAccount: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol
    private let userRepo: UserRepository
    private let notificationService = NotificationService.shared

    init(context: ModelContext, authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
        self.userRepo = UserRepository(context: context)
    }

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case createAccount
        case setGoal
        case permissions
        case done

        var title: String {
            switch self {
            case .welcome: return "Welcome to ForgeFit"
            case .createAccount: return "Create your account"
            case .setGoal: return "Set your weekly goal"
            case .permissions: return "Stay on track"
            case .done: return "You\'re all set"
            }
        }
    }

    func advance() {
        let steps = OnboardingStep.allCases
        guard let current = steps.firstIndex(of: currentStep),
              current + 1 < steps.count else {
            finish()
            return
        }
        currentStep = steps[current + 1]
    }

    func createAccount() {
        guard !displayName.isEmpty, !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        isCreatingAccount = true
        errorMessage = nil
        Task {
            do {
                let result = try await authService.createAccount(
                    email: email, password: password, username: username
                )
                let _ = userRepo.createUser(
                    id: result.userId,
                    username: username,
                    displayName: displayName,
                    email: email
                )
                try userRepo.save()
                await MainActor.run {
                    isCreatingAccount = false
                    advance()
                }
            } catch {
                await MainActor.run {
                    isCreatingAccount = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveGoal() {
        // Update settings
        advance()
    }

    func requestNotifications() {
        Task {
            let _ = await notificationService.requestPermission()
            await MainActor.run { advance() }
        }
    }

    func skipNotifications() {
        advance()
    }

    private func finish() {
        currentStep = .done
    }
}
