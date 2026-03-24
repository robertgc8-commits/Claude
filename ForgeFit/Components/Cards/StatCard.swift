import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    var trend: TrendIndicator? = nil

    enum TrendIndicator {
        case up, down, neutral
        var color: Color { self == .up ? .ffGreen : self == .down ? .ffRed : .ffSubtext }
        var icon: String { self == .up ? "arrow.up.right" : self == .down ? "arrow.down.right" : "minus" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                Spacer()
                if let trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(trend.color)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ffText)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ffSubtext)
                }
            }
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ffSubtext)
        }
        .padding(16)
        .ffCard()
    }
}
