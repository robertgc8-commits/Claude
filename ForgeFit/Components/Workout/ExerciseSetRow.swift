import SwiftUI

struct ExerciseSetRow: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    let lastReps: Int?
    let lastWeight: Double?
    let isPR: Bool
    var onComplete: () -> Void
    var onDelete: () -> Void

    @FocusState private var repsFieldFocused: Bool
    @FocusState private var weightFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Set number / warmup indicator
            Text(set.isWarmup ? "W" : "\(setNumber)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(set.isWarmup ? Color.ffSubtext : Color.ffAccent)
                .frame(width: 24)

            // Previous performance hint
            VStack(spacing: 1) {
                if let w = lastWeight, let r = lastReps {
                    Text("\(String(format: "%.1f", w))kg")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ffSubtext)
                    Text("\(r) reps")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ffSubtext)
                } else {
                    Text("—")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ffBorder)
                }
            }
            .frame(width: 44)

            Spacer()

            // Weight field
            HStack(spacing: 2) {
                TextField("0", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .focused($weightFieldFocused)
                Text("kg")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.ffSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("×")
                .foregroundStyle(Color.ffSubtext)

            // Reps field
            HStack(spacing: 2) {
                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 36)
                    .focused($repsFieldFocused)
                Text("reps")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.ffSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Complete / PR indicator
            Button(action: {
                HapticFeedback.impact(.light)
                onComplete()
            }) {
                ZStack {
                    Circle()
                        .fill(set.isCompleted ? Color.ffGreen : Color.ffSurface2)
                        .frame(width: 32, height: 32)
                    if isPR {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.ffGold)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(set.isCompleted ? .white : Color.ffSubtext)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
