import Foundation

/// Associates a Gregorian date with its corresponding lunar phase and calendar display metadata.
///
/// Bridges the gap between the standard calendar system and the Hawaiian lunar calendar,
/// providing all necessary data for calendar grid display and phase information.
struct MoonDay: Identifiable, Hashable {
    /// Stable identifier.
    let id = UUID()
    /// The Gregorian date for this entry.
    let date: Date
    /// The lunar day index (1...30) used for selecting icons.
    let day: Int
    /// The day of the Gregorian month used for calendar labelling.
    let calendarDay: Int
    /// Indicates if this day belongs to an overlapping month when constructing
    /// calendar grids.
    let isOverlap: Bool
    /// The lunar phase for this day.
    let phase: MoonPhase
}