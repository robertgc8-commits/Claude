import SwiftUI

extension View {
    func ffCard() -> some View {
        self
            .background(Color.ffSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func ffCard2() -> some View {
        self
            .background(Color.ffSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func ffSectionHeader() -> some View {
        self
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.ffSubtext)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    /// Dimmed overlay for loading states
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.ffBackground.opacity(0.6)
                    ProgressView().tint(Color.ffAccent)
                }
            }
        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Haptic
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
