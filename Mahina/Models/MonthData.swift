import Foundation

/// Encapsulates data for a Gregorian month along with its derived lunar calendar.
///
/// This type bundles metadata about a month and two collections of `MoonDay`
/// instances: one representing the built lunar month and one representing the
/// padded calendar view.
struct MonthData: Identifiable, Hashable {
    /// Stable identifier.
    let id = UUID()
    /// The numeric month (1...12).
    let monthNumber: Int
    /// The localized name of the month (e.g. "January").
    let monthName: String
    /// The full year (e.g. 2025).
    let year: Int
    /// The number of days in the month.
    let monthDays: Int
    /// The zero‑based weekday index of the first day of the month (0 = Sunday).
    let monthStartWeekdayIndex: Int
    /// The lunar calendar for display, including leading/trailing overlaps.
    let monthCalendar: [MoonDay]
    /// The continuous lunar month slice for this Gregorian month.
    let monthBuilt: [MoonDay]
}