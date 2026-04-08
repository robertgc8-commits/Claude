import SwiftUI

struct ExerciseSetRow: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    let lastReps: Int?
    let lastWeight: Double?
    let isPR: Bool
    var unit: WeightUnit = .kg
    var onComplete: () -> Void
    var onDelete: () -> Void

    @FocusState private var repsFieldFocused: Bool
    @FocusState private var weightFieldFocused: Bool

    @State private var showingPlateCalculator = false

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Set number + optional DS badge
                VStack(alignment: .center, spacing: 2) {
                    Text(set.isWarmup ? "W" : "\(setNumber)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(set.isWarmup ? Color.ffSubtext : Color.ffAccent)
                    if set.isDropSet {
                        Text("DS")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.ffOrange)
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.18), value: set.isDropSet)

                // Previous performance hint
                VStack(spacing: 1) {
                    if let w = lastWeight, let r = lastReps {
                        Text("\(String(format: "%.1f", w))kg")
                            .font(.system(size: 10)).foregroundStyle(Color.ffSubtext)
                        Text("\(r) reps")
                            .font(.system(size: 10)).foregroundStyle(Color.ffSubtext)
                    } else {
                        Text("—").font(.system(size: 10)).foregroundStyle(Color.ffBorder)
                    }
                }
                .frame(width: 44)

                Spacer()

                // Weight field + plate calculator button
                HStack(spacing: 4) {
                    HStack(spacing: 2) {
                        TextField("0", value: $set.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 52)
                            .focused($weightFieldFocused)
                        Text(unit.label).font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color.ffSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Plate calculator icon
                    Button {
                        HapticFeedback.impact(.light)
                        showingPlateCalculator = true
                    } label: {
                        Image(systemName: "scalemass")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.ffSubtext)
                            .frame(width: 26, height: 26)
                            .background(Color.ffSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                Text("×").foregroundStyle(Color.ffSubtext)

                // Reps field
                HStack(spacing: 2) {
                    TextField("0", value: $set.reps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                        .focused($repsFieldFocused)
                    Text("reps").font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Color.ffSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Complete / PR button
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
                                .font(.system(size: 12)).foregroundStyle(Color.ffGold)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(set.isCompleted ? .white : Color.ffSubtext)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // RPE + Drop Set row — shown after set is completed
            if set.isCompleted {
                HStack(spacing: 6) {
                    Text("RPE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.ffSubtext)
                        .frame(width: 28)

                    ForEach(1...10, id: \.self) { rpe in
                        Button {
                            HapticFeedback.impact(.light)
                            set.rpe = set.rpe == rpe ? nil : rpe
                        } label: {
                            Text("\(rpe)")
                                .font(.system(size: 11, weight: set.rpe == rpe ? .black : .regular))
                                .foregroundStyle(set.rpe == rpe ? .white : Color.ffSubtext)
                                .frame(width: 24, height: 22)
                                .background(set.rpe == rpe ? rpeColor(rpe) : Color.ffSurface2)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Drop Set toggle capsule
                    Button {
                        HapticFeedback.impact(.light)
                        set.isDropSet.toggle()
                    } label: {
                        Text("Drop Set")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(set.isDropSet ? .white : Color.ffOrange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(set.isDropSet ? Color.ffOrange : Color.ffOrange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.18), value: set.isDropSet)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingPlateCalculator) {
            PlateCalculatorView(targetWeight: set.weight > 0 ? set.weight : 20, unit: unit)
        }
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...5: return Color.ffGreen
        case 6...7: return Color.ffAccent
        case 8...9: return Color.ffGold
        default:    return Color.ffRed
        }
    }
}
