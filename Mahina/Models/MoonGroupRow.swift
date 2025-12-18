import Foundation

/// A data model describing a high‑level group of lunar days and their fill state.
///
/// Instances of this type are used to drive the phase group UI but contain no
/// view logic themselves.
struct MoonGroupRow: Identifiable, Hashable {
    /// A simple representation of a single day within a group.
    struct Day: Identifiable, Hashable {
        let id = UUID()
        /// The lunar day index (1...30). The value 31 may be used as a placeholder
        /// when a Gregorian month has 31 days.
        let lunarDay: Int
        /// The corresponding Gregorian calendar day (1...31) if it falls within the
        /// current month; otherwise `nil` when the lunar day has no matching
        /// Gregorian date in this context.
        let calendarDay: Int?
        /// Indicates whether the day is considered filled relative to the active
        /// selection.
        let isFilled: Bool
    }
    let id = UUID()
    /// The user‑visible name of the group.
    let name: String
    /// A description of the group.
    let description: String
    /// The English meaning of the group name.
    let englishMeaning: String
    /// The days within the group.
    let days: [Day]
    /// Indicates whether this group contains the active lunar day.
    let isActiveGroup: Bool
}
