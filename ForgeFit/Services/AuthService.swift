import Foundation
import Combine

/// Protocol-driven auth service. Production implementation uses Firebase Auth.
/// MockAuthService is used for development and testing.
protocol AuthServiceProtocol {
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
    func signInWithApple() async throws -> AuthResult
    func signInWithEmail(_ email: String, password: String) async throws -> AuthResult
    func createAccount(email: String, password: String, username: String) async throws -> AuthResult
    func signOut() throws
    func resetPassword(email: String) async throws
}

struct AuthResult {
    let userId: String
    let email: String
    let isNewUser: Bool
}

// MARK: - Mock Implementation
final class MockAuthService: AuthServiceProtocol {
    var currentUserId: String? = "mock_user_001"
    var isAuthenticated: Bool = true

    func signInWithApple() async throws -> AuthResult {
        return AuthResult(userId: "mock_user_001", email: "user@example.com", isNewUser: false)
    }

    func signInWithEmail(_ email: String, password: String) async throws -> AuthResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        return AuthResult(userId: "mock_user_001", email: email, isNewUser: false)
    }

    func createAccount(email: String, password: String, username: String) async throws -> AuthResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        return AuthResult(userId: UUID().uuidString, email: email, isNewUser: true)
    }

    func signOut() throws {}

    func resetPassword(email: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}
