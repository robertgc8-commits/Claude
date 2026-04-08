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
            if let e1rm = estimated1RM, pr.reps > 1 {
                return "\(String(format: "%.1f", pr.weight))kg · ~\(String(format: "%.1f", e1rm))kg est. 1RM"
            }
            return "\(String(format: "%.1f", pr.weight))kg × \(pr.reps) reps"
        case .mostRepsAtWeight:
            return "\(pr.reps) reps @ \(String(format: "%.1f", pr.weight))kg"
        case .highestVolume, .highestSessionVolume:
            return "\(pr.value.volumeDisplay())kg volume"
        }
    }

    /// Brzycki 1RM estimate: weight / (1.0278 - 0.0278 × reps)
    private var estimated1RM: Double? {
        guard pr.reps > 0 && pr.reps < 37 && pr.weight > 0 else { return nil }
        if pr.reps == 1 { return pr.weight }
        return pr.weight / (1.0278 - 0.0278 * Double(pr.reps))
    }
}
