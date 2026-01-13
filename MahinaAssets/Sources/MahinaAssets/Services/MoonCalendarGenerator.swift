import Foundation

/// Core service for computing lunar phases and generating Hawaiian lunar calendar data.
///
/// Uses a continuous lunar age model based on synodic month calculations to map
/// Gregorian dates to the traditional 30-day Hawaiian lunar calendar system.
/// Provides calendar grid generation and phase group organization functionality.
public enum MoonCalendarGenerator {

    // MARK: - Constants

    /// Approximate synodic month length in days (time from new moon to new moon)
    private static let synodicLength: Double = 29.530588

    // MARK: - Lunar Age Calculation

    /// Returns the approximate age of the moon in days since the last new moon
    /// (0 ..< synodicLength).
    ///
    /// This uses a fixed reference new moon (2024-01-11) and advances continuously,
    /// independent of Gregorian month boundaries.
    public static func lunarAge(for date: Date) -> Double {
        let cal = Calendar.current
        // Reference new moon anchored to 2024-01-11.
        var ref = DateComponents()
        ref.year = 2024
        ref.month = 1
        ref.day = 11
        let refDate = cal.date(from: ref) ?? Date(timeIntervalSince1970: 0)

        let daysDiff = date.timeIntervalSince(refDate) / 86400.0
        let mod = daysDiff.truncatingRemainder(dividingBy: synodicLength)
        return mod >= 0 ? mod : (mod + synodicLength)
    }

    // MARK: - Month Data Generation

    /// Builds `MonthData` for the Gregorian month containing `monthDate` using the
    /// continuous lunar age model.  A `newMoonProvider` closure parameter exists for
    /// backwards compatibility but is ignored.
    ///
    /// - Parameter includeOverlap: When `true`, the returned `monthCalendar` will include
    ///   leading and trailing days from adjacent months to form a padded calendar grid.
    ///   When `false`, only the days that fall within the target Gregorian month are
    ///   included.
    public static func buildMonthData(for monthDate: Date, includeOverlap: Bool = true) -> MonthData {
        return buildMonthData(for: monthDate, includeOverlap: includeOverlap, newMoonProvider: { _, _ in 0 })
    }

    /// Builds `MonthData` for the Gregorian month containing `monthDate`.
    ///
    /// - Parameters:
    ///   - monthDate: A date within the Gregorian month to build.
    ///   - includeOverlap: When `true`, the returned `monthCalendar` will include
    ///     leading and trailing days from adjacent months to form a padded calendar grid.
    ///     When `false`, only the days that fall within the target Gregorian month are
    ///     included.
    ///   - newMoonProvider: Retained for API compatibility but ignored; phases are
    ///     derived from the continuous `lunarAge(for:)` model.
    public static func buildMonthData(for monthDate: Date, includeOverlap: Bool, newMoonProvider: (Int, Int) -> Int) -> MonthData {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthDate)
        let safeMonthDate = cal.date(from: comps) ?? monthDate

        let monthNumber = comps.month ?? 1
        let year = comps.year ?? 0
        let monthDays = daysInMonth(for: safeMonthDate)
        let monthNameStr = monthName(for: safeMonthDate)

        // Build continuous lunar month slice for this Gregorian month
        let monthBuilt = builtMonth(for: safeMonthDate, overlap: false)

        if includeOverlap == false {
            let startIdx = startOfMonthIndex(for: monthBuilt.first?.date ?? safeMonthDate)
            return MonthData(
                monthNumber: monthNumber,
                monthName: monthNameStr,
                year: year,
                monthDays: monthDays,
                monthStartWeekdayIndex: startIdx,
                monthCalendar: monthBuilt,
                monthBuilt: monthBuilt
            )
        }

        guard let prevMonth = cal.date(byAdding: .month, value: -1, to: safeMonthDate),
              let nextMonth = cal.date(byAdding: .month, value: 1, to: safeMonthDate) else {
            return MonthData(
                monthNumber: monthNumber,
                monthName: monthNameStr,
                year: year,
                monthDays: monthDays,
                monthStartWeekdayIndex: startOfMonthIndex(for: safeMonthDate),
                monthCalendar: monthBuilt,
                monthBuilt: monthBuilt
            )
        }

        // Build a month grid: pad leading days from previous month and
        // trailing days from next month.  Use 5 or 6 rows depending on need.
        let startIdx = startOfMonthIndex(for: monthBuilt.first?.date ?? safeMonthDate)
        let requiredCells = startIdx + monthBuilt.count
        let lengthOfCalendar = (requiredCells <= 35) ? 35 : 42

        // Leading overlap from previous month: take the last `startIdx` days
        var monthBuiltPrev: [MoonDay] = []
        if startIdx > 0 {
            let prevBuilt = builtMonth(for: prevMonth, overlap: true)
            monthBuiltPrev = Array(prevBuilt.suffix(startIdx))
        }

        // Trailing overlap from next month: fill remaining slots to reach length
        let used = monthBuiltPrev.count + monthBuilt.count
        let remaining = max(0, lengthOfCalendar - used)
        let monthBuiltNext = Array(builtMonth(for: nextMonth, overlap: true).prefix(remaining))

        let calendarCombined = monthBuiltPrev + monthBuilt + monthBuiltNext

        return MonthData(
            monthNumber: monthNumber,
            monthName: monthNameStr,
            year: year,
            monthDays: monthDays,
            monthStartWeekdayIndex: startIdx,
            monthCalendar: calendarCombined,
            monthBuilt: monthBuilt
        )
    }

    /// Generates an array of `MoonDay` objects representing the lunar days in the
    /// Gregorian month anchored at `refDate`.  If `overlap` is true, the days are
    /// labelled as overlaps when constructing padded calendar grids.
    public static func builtMonth(for refDate: Date, overlap: Bool = false) -> [MoonDay] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: refDate) ?? 1..<29
        let days = Array(range)
        let comps = cal.dateComponents([.year, .month], from: refDate)
        let baseDate = cal.date(from: comps) ?? refDate

        return days.compactMap { d -> MoonDay? in
            guard let date = cal.date(byAdding: .day, value: d - 1, to: baseDate) else { return nil }
            let phaseResult = phase(for: date)
            return MoonDay(
                date: date,
                calendarDay: d,
                isOverlap: overlap,
                phase: phaseResult
            )
        }
    }

    // MARK: - Calendar Helper Functions

    /// Calculates the zero-based index of the weekday for the first day of the
    /// month containing `date` (0 = Sunday).
    public static func startOfMonthIndex(for date: Date) -> Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        return (weekday + 6) % 7
    }

    /// Returns the number of days in the month containing `date`.
    public static func daysInMonth(for date: Date) -> Int {
        let cal = Calendar.current
        return cal.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// Provides the localized month name for the month containing `date`.
    public static func monthName(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        return df.monthSymbols[Calendar.current.component(.month, from: date) - 1]
    }

    // MARK: - Transition Detection

    /*
     * Culturally significant phases in the Hawaiian lunar calendar:
     * - Hilo (1): New Moon - beginning of the lunar month
     * - Akua (14): Full Moon - the night of the full moon
     * - Muku (30): Last dark phase before New Moon
     *
     * These represent the major astronomical markers that Hawaiian
     * practitioners would note as significant transition points.
     * We exclude Hoku (15) to avoid flagging consecutive days.
     */
    private static let significantPhases: Set<Int> = [1, 14, 30]

    /// Cache of first transition day per calendar month to ensure only one per month
    private static nonisolated(unsafe) var monthTransitionCache: [String: Int] = [:]

    /// Determines if this date is the FIRST culturally significant phase transition
    /// in its calendar month. This ensures exactly one transition day per month.
    ///
    /// Checks if the phase changes between 6am and 6pm, AND if the transition is
    /// INTO one of the significant phases (Hilo, Akua, or Muku), AND if this is
    /// the first such transition in the calendar month.
    ///
    /// Returns: (endingPhase, beginningPhase) - the morning phase and the evening phase
    private static func transitionInfo(for date: Date) -> (ending: Int, beginning: Int)? {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)

        // Check phases at morning (6am) and evening (6pm)
        guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
              let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay) else {
            return nil
        }

        // Calculate phase at each time point
        func phaseAt(_ time: Date) -> Int {
            let age = lunarAge(for: time)
            let dayInCycle = (age / synodicLength) * 30.0
            var phase = Int(round(dayInCycle))
            if phase <= 0 { phase = 1 }
            if phase > 30 { phase = 1 }
            return phase
        }

        let morningPhase = phaseAt(morning)
        let eveningPhase = phaseAt(evening)

        // Must be a phase change into a significant phase
        guard morningPhase != eveningPhase,
              significantPhases.contains(eveningPhase) else {
            return nil
        }

        // Check if this is the first transition day of the month
        let dayOfMonth = cal.component(.day, from: date)
        let firstTransitionDay = findFirstTransitionDayOfMonth(for: date)

        guard dayOfMonth == firstTransitionDay else {
            return nil
        }

        return (ending: morningPhase, beginning: eveningPhase)
    }

    /// Finds the first day of the month that has a significant phase transition.
    /// Results are cached for performance.
    private static func findFirstTransitionDayOfMonth(for date: Date) -> Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        let cacheKey = "\(comps.year ?? 0)-\(comps.month ?? 0)"

        // Return cached result if available
        if let cached = monthTransitionCache[cacheKey] {
            return cached
        }

        // Find first transition day by scanning the month
        guard let monthStart = cal.date(from: comps) else { return 0 }
        let daysInMonth = cal.range(of: .day, in: .month, for: date)?.count ?? 31

        for day in 1...daysInMonth {
            guard let dayDate = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let startOfDay = cal.startOfDay(for: dayDate)

            guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                  let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay) else { continue }

            let mAge = lunarAge(for: morning)
            let eAge = lunarAge(for: evening)

            var mPhase = Int(round((mAge / synodicLength) * 30.0))
            var ePhase = Int(round((eAge / synodicLength) * 30.0))
            if mPhase <= 0 { mPhase = 1 }
            if mPhase > 30 { mPhase = 1 }
            if ePhase <= 0 { ePhase = 1 }
            if ePhase > 30 { ePhase = 1 }

            if mPhase != ePhase && significantPhases.contains(ePhase) {
                monthTransitionCache[cacheKey] = day
                return day
            }
        }

        // No transition found this month
        monthTransitionCache[cacheKey] = 0
        return 0
    }

    // MARK: - Phase Lookup Functions

    /// Returns the `MoonPhase` corresponding to a specific lunar day index (1...30).
    public static func moonPhase(for dayRef: Int) -> MoonPhase {
        let normalized = max(1, min(30, dayRef))
        let phase = LunarPhases.phase(for: normalized)

        let group: MoonGroup
        if (1...10).contains(normalized) {
            group = .hoonui
        } else if (11...16).contains(normalized) {
            group = .poepoe
        } else {
            group = .emi
        }
        let meta = group.metadata

        let gridPosition: Int
        switch group {
        case .hoonui:
            gridPosition = (normalized - 1) + 1
        case .poepoe:
            gridPosition = (normalized - 11) + 12
        case .emi:
            gridPosition = (normalized - 17) + 19
        }

        return MoonPhase(
            day: normalized,
            name: phase?.name ?? "Unknown",
            description: phase?.description ?? "Unknown phase",
            planting: phase?.planting ?? "No guidance available",
            fishing: phase?.fishing ?? "No guidance available",
            gridPosition: gridPosition,
            groupName: meta.name,
            groupDescription: meta.description
        )
    }

    // MARK: - Group Row Generation

    /// Builds three group rows (Hoʻonui, Poepoe, Emi) with day fill state for the
    /// given month and active date.
    public static func buildGroupRows(
        monthData: MonthData,
        activeDate: Date,
        calendar: Calendar = .current
    ) -> [MoonGroupRow] {
        // (name, description, englishMeaning, lunar day range)
        let groups: [(String, String, String, ClosedRange<Int>)] = [
            (MoonGroup.hoonui.metadata.name, MoonGroup.hoonui.metadata.description, MoonGroup.hoonui.metadata.englishMeaning, 1...10),
            (MoonGroup.poepoe.metadata.name, MoonGroup.poepoe.metadata.description, MoonGroup.poepoe.metadata.englishMeaning, 11...16),
            (MoonGroup.emi.metadata.name, MoonGroup.emi.metadata.description, MoonGroup.emi.metadata.englishMeaning, 17...30)
        ]

        // Map lunar day -> calendar day for this built month
        var lunarToCalendar: [Int: Int] = [:]
        for md in monthData.monthBuilt {
            lunarToCalendar[md.phase.primary.day] = md.calendarDay
        }

        // Determine the active lunar day from the primary phase
        let cal = calendar
        let activeLunarDay: Int = {
            if let moonDay = monthData.monthBuilt.first(where: { cal.isDate($0.date, inSameDayAs: activeDate) }) {
                return moonDay.phase.primary.day
            } else {
                return phase(for: activeDate).primary.day
            }
        }()

        var rows: [MoonGroupRow] = []
        for (_, g) in groups.enumerated() {
            let (name, description, englishMeaning, range) = g
            let dayModels: [MoonGroupRow.Day] = range.map { lunarDay in
                let calDay = lunarToCalendar[lunarDay]
                // Fill up to and including the active primary lunar day
                let filled = lunarDay <= activeLunarDay
                return MoonGroupRow.Day(
                    lunarDay: lunarDay,
                    calendarDay: calDay,
                    isFilled: filled
                )
            }

            // Active group is whichever contains the primary phase
            let isActive = range.contains(activeLunarDay)
            rows.append(
                MoonGroupRow(
                    name: name,
                    description: description,
                    englishMeaning: englishMeaning,
                    days: dayModels,
                    isActiveGroup: isActive
                )
            )
        }

        return rows
    }

    /// Returns the `PhaseResult` for a specific Gregorian date, including
    /// transition day information when applicable.
    ///
    /// This uses the continuous lunar age model (`lunarAge(for:)`) rather than
    /// any month-local new moon provider.
    ///
    /// On transition days, `primary` is the phase beginning at moonfall (what people
    /// experience that evening), and `secondary` is the phase that's ending.
    public static func phase(for date: Date) -> PhaseResult {
        // Normalize to the start of the local day so that "today" is
        // interpreted consistently regardless of the current time.
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)

        let age = lunarAge(for: startOfDay)

        // More robust lunar day calculation that avoids skipping days
        // Map age directly to 1-30 range with proper rounding
        let dayInCycle = (age / synodicLength) * 30.0
        var dayRef = Int(round(dayInCycle))

        // Handle edge cases at cycle boundaries
        // dayInCycle 0-0.5 rounds to 0, but this is START of new cycle = phase 1
        if dayRef <= 0 { dayRef = 1 }
        if dayRef > 30 { dayRef = 1 }

        // Check for transition day
        if let transition = transitionInfo(for: date) {
            /*
             * On transition days, primary is the "morning" phase (ending phase)
             * and secondary is the "evening" phase (beginning at moonfall).
             * This matches the printed Hawaiian calendar which shows the ending
             * phase as the main display, with the new phase noted as beginning.
             * This ensures clean day-by-day progression in the calendar.
             */
            let primary = moonPhase(for: transition.ending)
            let secondary = moonPhase(for: transition.beginning)
            return PhaseResult(primary: primary, secondary: secondary)
        }

        // Regular day - just the rounded phase
        let primary = moonPhase(for: dayRef)
        return PhaseResult(primary: primary, secondary: nil)
    }
}
