import Foundation
import SwiftData

@MainActor
final class UserRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCurrentUser(userId: String) throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userId }
        )
        return try context.fetch(descriptor).first
    }

    func fetchSettings(userId: String) throws -> UserSettings? {
        let descriptor = FetchDescriptor<UserSettings>(
            predicate: #Predicate { $0.userId == userId }
        )
        return try context.fetch(descriptor).first
    }

    func createUser(id: String, username: String, displayName: String, email: String) -> User {
        let user = User(id: id, username: username, displayName: displayName, email: email)
        let settings = UserSettings(userId: id)
        context.insert(user)
        context.insert(settings)
        user.settings = settings
        return user
    }

    func save() throws { try context.save() }
}
