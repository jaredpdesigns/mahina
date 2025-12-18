import Foundation

/// Core service for computing lunar phases and generating Hawaiian lunar calendar data.
///
/// Uses a continuous lunar age model based on synodic month calculations to map
/// Gregorian dates to the traditional 30-day Hawaiian lunar calendar system.
/// Provides calendar grid generation and phase group organization functionality.
enum MoonCalendarGenerator {

    // MARK: - Constants

    /// Approximate synodic month length in days (time from new moon to new moon)
    private static let synodicLength: Double = 29.530588

    // MARK: - Lunar Age Calculation

    /// Returns the approximate age of the moon in days since the last new moon
    /// (0 ..< synodicLength).
    ///
    /// This uses a fixed reference new moon (2024-01-11) and advances continuously,
    /// independent of Gregorian month boundaries.
    static func lunarAge(for date: Date) -> Double {
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
    static func buildMonthData(for monthDate: Date, includeOverlap: Bool = true) -> MonthData {
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
    static func buildMonthData(for monthDate: Date, includeOverlap: Bool, newMoonProvider: (Int, Int) -> Int) -> MonthData {
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
    static func builtMonth(for refDate: Date, overlap: Bool = false) -> [MoonDay] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: refDate) ?? 1..<29
        let days = Array(range)
        let comps = cal.dateComponents([.year, .month], from: refDate)
        let baseDate = cal.date(from: comps) ?? refDate

        return days.compactMap { d -> MoonDay? in
            guard let date = cal.date(byAdding: .day, value: d - 1, to: baseDate) else { return nil }
            let phase = phase(for: date)
            return MoonDay(
                date: date,
                day: phase.day,
                calendarDay: d,
                isOverlap: overlap,
                phase: phase
            )
        }
    }

    // MARK: - Calendar Helper Functions

    /// Calculates the zero-based index of the weekday for the first day of the
    /// month containing `date` (0 = Sunday).
    static func startOfMonthIndex(for date: Date) -> Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        return (weekday + 6) % 7
    }

    /// Returns the number of days in the month containing `date`.
    static func daysInMonth(for date: Date) -> Int {
        let cal = Calendar.current
        return cal.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// Provides the localized month name for the month containing `date`.
    static func monthName(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        return df.monthSymbols[Calendar.current.component(.month, from: date) - 1]
    }

    // MARK: - Phase Lookup Functions

    /// Returns the `MoonPhase` corresponding to a specific lunar day index (1...30).
    static func moonPhase(for dayRef: Int) -> MoonPhase {
        let normalized = max(1, min(30, dayRef))
        let phase = phases.first(where: { $0.day == normalized })

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

    // MARK: - Phase Data

    /// Complete lookup table of Hawaiian lunar calendar phases with traditional guidance
    private static let phases: [(day: Int, name: String, description: String, planting: String, fishing: String)] = [
        (1, "Hilo",
         "Slender new-moon, sliver at sunset",
         "Plant underground crops that ‘hide’ in the soil",
         "Reef fish hide, deep-sea fishing is good"
        ),
        (2, "Hoaka",
         "Second night, thin crescent ‘spirit’ night",
         "Limit planting, observe conditions",
         "Fish are frightened away, poor fishing"
        ),
        (3, "Kūkahi",
         "First night of Kū, moon growing",
         "Good time to plant ʻuala and kalo",
         "Good fishing conditions beginning to change"
        ),
        (4, "Kūlua",
         "Second night of Kū, continued growth",
         "Continue planting upright strong-growing crops",
         "Good fishing period"
        ),
        (5, "Kūkolu",
         "Third night of Kū, steady growth continues",
         "Plant crops you want to grow tall and strong",
         "Good fishing period"
        ),
        (6, "Kūpau",
         "Fourth night of Kū, end of Kū phase",
         "Finish planting of taro and other upright crops",
         "Good fishing period"
        ),
        (7, "ʻOlekūkahi",
         "First ʻOle night, considered unproductive",
         "Avoid planting, focus on weeding and maintenance",
         "Fishing poor due to high tides and rough ocean"
        ),
        (8, "ʻOlekūlua",
         "Second ʻOle night, unproductive period continues",
         "Avoid planting, continue garden upkeep only",
         "Fishing remains poor, rough conditions"
        ),
        (9, "ʻOlekūkolu",
         "Third ʻOle night, rough conditions persist",
         "Planting discouraged, maintain and tidy fields",
         "Fishing poor, seas unsettled"
        ),
        (10, "ʻOlepau",
         "Fourth ʻOle night, end of rough period",
         "Little planting, finish maintenance work",
         "Fishing still poor, conditions moderating"
        ),
        (11, "Huna",
         "Hidden-horns moon, small but rounding",
         "Good for root vegetables and gourds that ‘hide’",
         "Good fishing as fish hide in their holes"
        ),
        (12, "Mōhalu",
         "Sacred night to Kāne, moon nearly full",
         "Good for planting vegetables to mirror the round moon",
         "Sea foods traditionally kapu, avoid fishing"
        ),
        (13, "Hua",
         "First of the four full moons, ‘egg fruit seed’",
         "Very good for planting fruiting and seed crops",
         "Good-luck night for fishing"
        ),
        (14, "Akua",
         "Second full moon, sacred to the gods",
         "Favorable for planting with offerings to the gods",
         "Good night for fishing"
        ),
        (15, "Hoku",
         "Fullest of the full moons, peak brightness",
         "Best for crops planted in rows",
         "Good fishing under bright full moon"
        ),
        (16, "Māhealani",
         "Last of the four full moons",
         "Good for all kinds of planting and work",
         "Good fishing, people take full advantage"
        ),
        (17, "Kulu",
         "Moon following the full-moon series",
         "Time to harvest and offer first fruits",
         "Fishing considered good"
        ),
        (18, "Lāʻaukūkahi",
         "First Lāʻau night, associated with trees and plants",
         "Focus on trees and medicinal plants, avoid tender fruit crops",
         "Fishing acceptable, attention on gathering plant medicines"
        ),
        (19, "Lāʻaukūlua",
         "Second Lāʻau night, tree focus continues",
         "Continue work with trees and herbs, avoid woody fruit set",
         "Fishing moderate, not the primary focus"
        ),
        (20, "Lāʻaupau",
         "Third Lāʻau night, completion of tree phase",
         "Complete work with trees and medicinal plants",
         "Fishing moderate, period centered on plants and healing"
        ),
        (21, "ʻOlekūkahi",
         "Unproductive ʻOle night returns",
         "Avoid planting, good for weeding and cleaning fields",
         "Fishing generally avoided, focus on prayers"
        ),
        (22, "ʻOlekūlua",
         "Second unproductive ʻOle night",
         "Continue field maintenance rather than planting",
         "Fishing avoided, little activity at sea"
        ),
        (23, "ʻOlepau",
         "Final ʻOle night, dedicated to Kāloa and Kanaloa",
         "Avoid planting, offer prayers instead",
         "Fishing generally avoided, day of worship"
        ),
        (24, "Kāloakūkahi",
         "First Kāloa night, beginning of Kāloa series",
         "Plant long-stemmed crops and vine plants",
         "Good fishing, especially for shellfish"
        ),
        (25, "Kāloakūlua",
         "Second Kāloa night, vine planting continues",
         "Continue planting vines and long-stemmed plants",
         "Good fishing, especially shellfish"
        ),
        (26, "Kāloapau",
         "Third Kāloa night, Kāloa phase completes",
         "Finish planting vines and long-stemmed crops",
         "Good fishing, shellfish and reef foods favored"
        ),
        (27, "Kāne",
         "Sacred night of worship to Kāne and Lono",
         "Little or no planting, focus on kapu observances",
         "Fishing generally set aside for prayer"
        ),
        (28, "Lono",
         "Second worship night, dedicated to Lono and rain",
         "No major planting, prayers for rain and fertility",
         "Fishing typically limited, focus on ceremony"
        ),
        (29, "Mauli",
         "Moon rises with daylight, ‘shadow of life’",
         "Light planting or garden preparation",
         "Fishing encouraged, lower tides favor activity"
        ),
        (30, "Muku",
         "Dark new-moon night, final phase",
         "Rest from planting and prepare for new cycle",
         "Fishing considered good on this dark moon"
        )
    ]

    // MARK: - Group Row Generation

    /// Builds three group rows (Hoʻonui, Poepoe, Emi) with day fill state for the
    /// given month and active date.
    static func buildGroupRows(
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
            lunarToCalendar[md.phase.day] = md.calendarDay
        }

        // Determine the active lunar day, preferring the phase stored in this month’s data
        let cal = calendar
        let activeLunarDay: Int = {
            if let moonDay = monthData.monthBuilt.first(where: { cal.isDate($0.date, inSameDayAs: activeDate) }) {
                return moonDay.phase.day
            } else {
                return phase(for: activeDate).day
            }
        }()

        var rows: [MoonGroupRow] = []
        for (_, g) in groups.enumerated() {
            let (name, description, englishMeaning, range) = g
            let dayModels: [MoonGroupRow.Day] = range.map { lunarDay in
                let calDay = lunarToCalendar[lunarDay]
                // A day is considered filled if its lunar day index is on or
                // before the active lunar day in the current cycle.
                let filled = lunarDay <= activeLunarDay
                return MoonGroupRow.Day(
                    lunarDay: lunarDay,
                    calendarDay: calDay,
                    isFilled: filled
                )
            }

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

    /// Returns the `MoonPhase` corresponding to a specific Gregorian date.
    ///
    /// This uses the continuous lunar age model (`lunarAge(for:)`) rather than
    /// any month-local new moon provider.
    static func phase(for date: Date) -> MoonPhase {
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
        if dayRef == 0 { dayRef = 30 } // Wrap around case - check first!
        if dayRef < 1 { dayRef = 1 }
        if dayRef > 30 { dayRef = 30 }

        return moonPhase(for: dayRef)
    }
}
