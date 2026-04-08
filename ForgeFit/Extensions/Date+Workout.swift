import Foundation

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }

    func relativeDisplay() -> String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func workoutDateDisplay() -> String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year) ? "EEEE, MMM d" : "MMM d, yyyy"
        return f.string(from: self)
    }

    func timeDisplay() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }

    var weekdayShort: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: self)
    }
}

extension Int {
    var durationFormatted: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

extension Double {
    func weightDisplay(unit: WeightUnit) -> String {
        let v = unit == .kg ? self : self * 2.20462
        if v == v.rounded() {
            return "\(Int(v))\(unit.label)"
        }
        return String(format: "%.1f%@", v, unit.label)
    }

    func volumeDisplay() -> String {
        if self >= 1000 {
            return String(format: "%.1fk", self / 1000)
        }
        return String(format: "%.0f", self)
    }
}
