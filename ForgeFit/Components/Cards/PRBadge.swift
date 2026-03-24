import SwiftUI

struct PRBadge: View {
    let pr: PersonalRecord
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            Image(systemName: pr.recordType.icon)
                .font(.system(size: compact ? 12 : 14, weight: .bold))
                .foregroundStyle(Color.ffGold)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("PR")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.ffGold)
                    Text(pr.exerciseName)
                        .font(.system(size: compact ? 13 : 14, weight: .semibold))
                        .foregroundStyle(Color.ffText)
                        .lineLimit(1)
                }
                Text(prDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            Spacer()
            Text(pr.achievedAt.relativeDisplay())
                .font(.system(size: 11))
                .foregroundStyle(Color.ffSubtext)
        }
        .padding(compact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.ffGold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.ffGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var prDetail: String {
        switch pr.recordType {
        case .heaviestWeight:
            return "\(String(format: "%.1f", pr.weight))kg"
        case .mostRepsAtWeight:
            return "\(pr.reps) reps @ \(String(format: "%.1f", pr.weight))kg"
        case .highestVolume, .highestSessionVolume:
            return "\(pr.value.volumeDisplay())kg volume"
        }
    }
}
