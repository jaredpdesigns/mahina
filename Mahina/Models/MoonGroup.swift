import Foundation

/// Represents the three major phases of the Hawaiian lunar calendar cycle.
///
/// The Hawaiian lunar calendar organizes the 30 days into three main groups,
/// each representing different energetic qualities and traditional activities.
enum MoonGroup {
    /// Growing/waxing moon phases - time of increase and expansion
    case hoonui
    /// Full moon phases - time of abundance and peak energy
    case poepoe
    /// Waning moon phases - time of release and renewal preparation
    case emi

    /// Returns the Hawaiian name, cultural description, and English translation for each group
    var metadata: (name: String, description: String, englishMeaning: String) {
        switch self {
        case .hoonui:
            return ("Hoʻonui", "Growing moon phases, a time of increase and expansion", "to grow bigger")
        case .poepoe:
            return ("Poepoe", "Full moon phases, a time of abundance and peak energy", "round")
        case .emi:
            return ("Emi", "Waning moon phases, a time of release and preparation for renewal", "to decrease")
        }
    }
}
