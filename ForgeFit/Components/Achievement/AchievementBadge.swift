import SwiftUI

struct AchievementBadge: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    let unlockDate: Date?
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large
        var iconSize: CGFloat { self == .small ? 16 : self == .medium ? 24 : 36 }
        var frameSize: CGFloat { self == .small ? 40 : self == .medium ? 60 : 80 }
        var cornerRadius: CGFloat { frameSize * 0.28 }
    }

    var body: some View {
        VStack(spacing: size == .small ? 4 : 8) {
            ZStack {
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .fill(
                        isUnlocked
                        ? LinearGradient(
                            colors: [definition.category.swiftColor, definition.category.swiftColor.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          )
                        : LinearGradient(colors: [Color.ffSurface2, Color.ffSurface2], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: size.frameSize, height: size.frameSize)

                Image(systemName: definition.iconName)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundStyle(isUnlocked ? .white : Color.ffSubtext.opacity(0.4))
            }

            if size != .small {
                Text(definition.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isUnlocked ? Color.ffText : Color.ffSubtext)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .opacity(isUnlocked ? 1 : 0.5)
    }
}

// MARK: - Toast overlay
struct AchievementToast: View {
    let definition: AchievementDefinition
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 14) {
                AchievementBadge(definition: definition, isUnlocked: true, unlockDate: nil, size: .small)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(definition.category.swiftColor)
                    Text(definition.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.ffText)
                }
                Spacer()
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ffSubtext)
                    .onTapGesture { isShowing = false }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.ffSurface)
                    .shadow(color: .black.opacity(0.4), radius: 20)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct AchievementToastOverlay: View {
    @EnvironmentObject var appState: AppState
    @State private var current: AchievementDefinition?
    @State private var isShowing = false

    var body: some View {
        ZStack {
            if isShowing, let achievement = current {
                AchievementToast(definition: achievement, isShowing: $isShowing)
                    .onAppear {
                        HapticFeedback.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation { isShowing = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showNext()
                            }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShowing)
        .onReceive(appState.$pendingAchievements) { pending in
            if !pending.isEmpty && !isShowing {
                showNext()
            }
        }
    }

    private func showNext() {
        if let next = appState.dequeueAchievement() {
            current = next
            withAnimation { isShowing = true }
        }
    }
}
