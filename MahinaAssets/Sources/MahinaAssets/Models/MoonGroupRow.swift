import Foundation

/// A data model describing a high‑level group of lunar days and their fill state.
///
/// Instances of this type are used to drive the phase group UI but contain no
/// view logic themselves.
public struct MoonGroupRow: Identifiable, Hashable {
    /// A simple representation of a single day within a group.
    public struct Day: Identifiable, Hashable {
        public let id = UUID()
        /// The lunar day index (1...30). The value 31 may be used as a placeholder
        /// when a Gregorian month has 31 days.
        public let lunarDay: Int
        /// The corresponding Gregorian calendar day (1...31) if it falls within the
        /// current month; otherwise `nil` when the lunar day has no matching
        /// Gregorian date in this context.
        public let calendarDay: Int?
        /// Indicates whether the day is considered filled relative to the active
        /// selection.
        public let isFilled: Bool

        public init(lunarDay: Int, calendarDay: Int?, isFilled: Bool) {
            self.lunarDay = lunarDay
            self.calendarDay = calendarDay
            self.isFilled = isFilled
        }
    }
    public let id = UUID()
    /// The user‑visible name of the group.
    public let name: String
    /// A description of the group.
    public let description: String
    /// The English meaning of the group name.
    public let englishMeaning: String
    /// The days within the group.
    public let days: [Day]
    /// Indicates whether this group contains the active lunar day.
    public let isActiveGroup: Bool

    public init(name: String, description: String, englishMeaning: String, days: [Day], isActiveGroup: Bool) {
        self.name = name
        self.description = description
        self.englishMeaning = englishMeaning
        self.days = days
        self.isActiveGroup = isActiveGroup
    }
}
