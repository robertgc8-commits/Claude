import SwiftUI

extension Color {
    // Brand
    static let ffAccent      = Color("ffAccent")       // Primary blue-ish accent
    static let ffBackground  = Color("ffBackground")   // Near-black background
    static let ffSurface     = Color("ffSurface")      // Card surface
    static let ffSurface2    = Color("ffSurface2")     // Elevated card
    static let ffText        = Color("ffText")         // Primary text
    static let ffSubtext     = Color("ffSubtext")      // Secondary text
    static let ffBorder      = Color("ffBorder")       // Subtle borders

    // Semantic
    static let ffRed         = Color("ffRed")          // Danger / strength PR
    static let ffOrange      = Color("ffOrange")       // Volume / warm
    static let ffGold        = Color("ffGold")         // Achievements / milestones
    static let ffGreen       = Color("ffGreen")        // Success
    static let ffPurple      = Color("ffPurple")       // Social
}

// Fallback colors when asset catalog is unavailable (previews, tests)
extension Color {
    static func ffColor(_ name: String) -> Color {
        switch name {
        case "ffAccent":     return Color(red: 0.24, green: 0.58, blue: 1.0)
        case "ffBackground": return Color(red: 0.07, green: 0.07, blue: 0.09)
        case "ffSurface":    return Color(red: 0.12, green: 0.12, blue: 0.15)
        case "ffSurface2":   return Color(red: 0.16, green: 0.16, blue: 0.20)
        case "ffText":       return Color.white
        case "ffSubtext":    return Color(white: 0.6)
        case "ffBorder":     return Color(white: 0.2)
        case "ffRed":        return Color(red: 1.0, green: 0.27, blue: 0.27)
        case "ffOrange":     return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "ffGold":       return Color(red: 1.0, green: 0.82, blue: 0.2)
        case "ffGreen":      return Color(red: 0.24, green: 0.84, blue: 0.48)
        case "ffPurple":     return Color(red: 0.6, green: 0.4, blue: 1.0)
        default:             return Color.gray
        }
    }
}

extension AchievementCategory {
    var swiftColor: Color {
        switch self {
        case .milestones:  return .ffGold
        case .consistency: return .ffAccent
        case .strength:    return .ffRed
        case .volume:      return .ffOrange
        case .social:      return .ffPurple
        }
    }
}
