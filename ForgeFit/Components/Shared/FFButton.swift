import SwiftUI

struct FFButton: View {
    enum Style { case primary, secondary, destructive }

    let title: String
    var style: Style = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            HapticFeedback.impact()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(backgroundColor)
                    .frame(height: 52)

                if isLoading {
                    ProgressView().tint(foregroundColor)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(foregroundColor)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
        .frame(maxWidth: .infinity)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:     return .ffAccent
        case .secondary:   return .ffSurface
        case .destructive: return .ffRed
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .ffText
        case .destructive: return .white
        }
    }
}
