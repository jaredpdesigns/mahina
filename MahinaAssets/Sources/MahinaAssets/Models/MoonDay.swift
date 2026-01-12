import Foundation

/// Associates a Gregorian date with its corresponding lunar phase and calendar display metadata.
///
/// Bridges the gap between the standard calendar system and the Hawaiian lunar calendar,
/// providing all necessary data for calendar grid display and phase information.
public struct MoonDay: Identifiable, Hashable {
    /// Stable identifier.
    public let id = UUID()
    /// The Gregorian date for this entry.
    public let date: Date
    /// The lunar day index (1...30) used for selecting icons.
    public let day: Int
    /// The day of the Gregorian month used for calendar labelling.
    public let calendarDay: Int
    /// Indicates if this day belongs to an overlapping month when constructing
    /// calendar grids.
    public let isOverlap: Bool
    /// The lunar phase for this day.
    public let phase: MoonPhase

    public init(date: Date, day: Int, calendarDay: Int, isOverlap: Bool, phase: MoonPhase) {
        self.date = date
        self.day = day
        self.calendarDay = calendarDay
        self.isOverlap = isOverlap
        self.phase = phase
    }
}