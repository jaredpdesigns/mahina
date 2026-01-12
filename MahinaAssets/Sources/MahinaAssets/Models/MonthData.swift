import Foundation

/// Encapsulates data for a Gregorian month along with its derived lunar calendar.
///
/// This type bundles metadata about a month and two collections of `MoonDay`
/// instances: one representing the built lunar month and one representing the
/// padded calendar view.
public struct MonthData: Identifiable, Hashable {
    /// Stable identifier.
    public let id = UUID()
    /// The numeric month (1...12).
    public let monthNumber: Int
    /// The localized name of the month (e.g. "January").
    public let monthName: String
    /// The full year (e.g. 2025).
    public let year: Int
    /// The number of days in the month.
    public let monthDays: Int
    /// The zero‑based weekday index of the first day of the month (0 = Sunday).
    public let monthStartWeekdayIndex: Int
    /// The lunar calendar for display, including leading/trailing overlaps.
    public let monthCalendar: [MoonDay]
    /// The continuous lunar month slice for this Gregorian month.
    public let monthBuilt: [MoonDay]

    public init(monthNumber: Int, monthName: String, year: Int, monthDays: Int, monthStartWeekdayIndex: Int, monthCalendar: [MoonDay], monthBuilt: [MoonDay]) {
        self.monthNumber = monthNumber
        self.monthName = monthName
        self.year = year
        self.monthDays = monthDays
        self.monthStartWeekdayIndex = monthStartWeekdayIndex
        self.monthCalendar = monthCalendar
        self.monthBuilt = monthBuilt
    }
}