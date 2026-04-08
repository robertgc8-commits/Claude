import SwiftUI

struct StreakCard: View {
    let status: StreakStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ffSubtext)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(status.currentStreak)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(status.currentStreak > 0 ? Color.ffOrange : Color.ffSubtext)
                        Text(status.currentStreak == 1 ? "week" : "weeks")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.ffSubtext)
                    }
                }
                Spacer()
                Image(systemName: status.currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 28))
                    .foregroundStyle(status.currentStreak > 0 ? Color.ffOrange : Color.ffSubtext)
            }

            // Weekly progress dots
            weeklyProgressDots

            HStack {
                Text(status.progressText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(status.isCurrentWeekComplete ? Color.ffGreen : Color.ffText)
                Spacer()
                if !status.isCurrentWeekComplete {
                    Text("\(status.remainingThisWeek) to go")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ffSubtext)
                } else {
                    Label("Week complete", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.ffGreen)
                }
            }
        }
        .padding(16)
        .ffCard()
    }

    private var weeklyProgressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<status.currentWeekTarget, id: \.self) { index in
                Circle()
                    .fill(index < status.currentWeekCompleted ? Color.ffOrange : Color.ffBorder)
                    .frame(width: 10, height: 10)
                    .scaleEffect(index < status.currentWeekCompleted ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: status.currentWeekCompleted)
            }
            Spacer()
        }
    }
}
