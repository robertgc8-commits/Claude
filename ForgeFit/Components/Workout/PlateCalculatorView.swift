import SwiftUI

struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    let unit: WeightUnit
    @State private var targetWeight: Double

    private let increment: Double

    // Standard Olympic barbell weight
    private var barbellWeight: Double { unit == .kg ? 20.0 : 44.0 }

    // Available plates per unit
    private var availablePlates: [Double] {
        unit == .kg
            ? [25, 20, 15, 10, 5, 2.5, 1.25]
            : [45, 35, 25, 10, 5, 2.5]
    }

    // Plate display colours
    private func plateColor(_ kg: Double) -> Color {
        switch kg {
        case 25, 45: return Color(red: 0.8, green: 0.15, blue: 0.15)   // red
        case 20, 35: return Color(red: 0.1, green: 0.35, blue: 0.8)    // blue
        case 15, 25: return Color(red: 0.9, green: 0.6, blue: 0.1)     // yellow/gold
        case 10:     return Color(red: 0.15, green: 0.55, blue: 0.25)  // green
        case 5:      return Color(red: 0.55, green: 0.55, blue: 0.55)  // grey
        default:     return Color(red: 0.85, green: 0.85, blue: 0.85)  // light grey
        }
    }

    // MARK: - Calculation

    struct PlateResult {
        let plates: [(weight: Double, count: Int)]  // largest first
        let achievable: Bool
        let weightPerSide: Double
    }

    private var calculation: PlateResult {
        let weightPerSide = (targetWeight - barbellWeight) / 2.0

        guard weightPerSide >= 0 else {
            return PlateResult(plates: [], achievable: targetWeight == barbellWeight, weightPerSide: 0)
        }
        if weightPerSide == 0 {
            return PlateResult(plates: [], achievable: true, weightPerSide: 0)
        }

        var remaining = weightPerSide
        var plateCounts: [(weight: Double, count: Int)] = []

        for plate in availablePlates {
            let count = Int(remaining / plate)
            if count > 0 {
                plateCounts.append((weight: plate, count: count))
                remaining -= Double(count) * plate
                remaining = (remaining * 1000).rounded() / 1000  // floating-point fix
            }
        }

        let achievable = remaining < 0.001  // effectively zero
        return PlateResult(plates: plateCounts, achievable: achievable, weightPerSide: weightPerSide)
    }

    init(targetWeight: Double, unit: WeightUnit) {
        self._targetWeight = State(initialValue: targetWeight)
        self.unit = unit
        self.increment = unit == .kg ? 2.5 : 5.0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weightAdjuster
                    barDiagram
                    plateBreakdown
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.ffBackground)
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ffAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Weight Adjuster

    private var weightAdjuster: some View {
        VStack(spacing: 12) {
            Text("Target Weight")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ffSubtext)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                Button {
                    HapticFeedback.impact(.light)
                    targetWeight = max(barbellWeight, targetWeight - increment)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.ffAccent)
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text(String(format: "%.2g", targetWeight))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ffText)
                    Text(unit.label)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ffSubtext)
                }
                .frame(minWidth: 100)

                Button {
                    HapticFeedback.impact(.light)
                    targetWeight += increment
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.ffAccent)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.ffSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack {
                Text("Bar: \(String(format: "%.4g", barbellWeight))\(unit.label)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
                Spacer()
                Text("Per side: \(String(format: "%.4g", max(0, (targetWeight - barbellWeight) / 2)))\(unit.label)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ffSubtext)
            }
        }
    }

    // MARK: - Visual Bar Diagram

    private var barDiagram: some View {
        VStack(spacing: 12) {
            Text("Plate Setup")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ffSubtext)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !calculation.achievable && targetWeight > barbellWeight {
                notAchievableBanner
            } else {
                plateVisual
            }
        }
    }

    private var notAchievableBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.ffGold)
            Text("Not achievable with standard plates")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.ffText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ffGold.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var plateVisual: some View {
        HStack(spacing: 0) {
            // Left side plates (reversed so innermost plate is closest to bar)
            HStack(spacing: 3) {
                ForEach(Array(expandedPlates(calculation.plates).reversed().enumerated()), id: \.offset) { _, plate in
                    plateCircle(plate)
                }
            }

            // Bar
            Rectangle()
                .fill(Color(white: 0.5))
                .frame(width: 48, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    Text("bar")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.ffBackground)
                )

            // Right side plates
            HStack(spacing: 3) {
                ForEach(Array(expandedPlates(calculation.plates).enumerated()), id: \.offset) { _, plate in
                    plateCircle(plate)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.ffSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: calculation.plates.map { $0.count })
    }

    private func plateCircle(_ weight: Double) -> some View {
        let height: CGFloat = plateHeight(weight)
        return RoundedRectangle(cornerRadius: 4)
            .fill(plateColor(weight))
            .frame(width: 18, height: height)
            .overlay(
                Text(formatPlateLabel(weight))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-90))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            )
    }

    private func plateHeight(_ weight: Double) -> CGFloat {
        let maxWeight: Double = unit == .kg ? 25 : 45
        let minH: CGFloat = 28
        let maxH: CGFloat = 66
        return minH + (maxH - minH) * CGFloat(weight / maxWeight)
    }

    private func formatPlateLabel(_ weight: Double) -> String {
        if weight == weight.rounded() {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }

    // Expand [(weight, count)] → flat [weight] list
    private func expandedPlates(_ plates: [(weight: Double, count: Int)]) -> [Double] {
        plates.flatMap { Array(repeating: $0.weight, count: $0.count) }
    }

    // MARK: - Plate Breakdown List

    private var plateBreakdown: some View {
        VStack(spacing: 12) {
            Text("Per Side")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ffSubtext)
                .frame(maxWidth: .infinity, alignment: .leading)

            if calculation.plates.isEmpty && calculation.achievable {
                HStack {
                    Text("Bar only — no plates needed")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ffSubtext)
                    Spacer()
                }
                .padding(14)
                .background(Color.ffSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if !calculation.plates.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(calculation.plates.enumerated()), id: \.offset) { index, entry in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(plateColor(entry.weight))
                                .frame(width: 14, height: 30)

                            Text("\(entry.count)×")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ffText)
                                .frame(width: 28, alignment: .trailing)

                            Text("\(formatPlateLabel(entry.weight))\(unit.label)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.ffText)

                            Spacer()

                            Text("= \(formatPlateLabel(Double(entry.count) * entry.weight))\(unit.label)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.ffSubtext)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if index < calculation.plates.count - 1 {
                            Divider().background(Color.ffBorder).padding(.horizontal, 14)
                        }
                    }

                    Divider().background(Color.ffBorder).padding(.horizontal, 14)

                    HStack {
                        Text("Total per side")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.ffSubtext)
                        Spacer()
                        Text("\(formatPlateLabel(calculation.weightPerSide))\(unit.label)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ffAccent)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .background(Color.ffSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
