import XCTest
@testable import MahinaAssets

/// Tests for data transformations and computed values that drive view rendering.
///
/// While SwiftUI views themselves are best tested via:
/// - Preview snapshots (visual inspection)
/// - UI tests (XCUITest for interaction flows)
/// - ViewInspector library (programmatic view inspection)
///
/// This file tests the DATA that feeds views, ensuring views receive correct
/// information. This approach offers:
/// - Fast execution (no view hierarchy creation)
/// - Deterministic results (no timing issues)
/// - Clear failure messages (data mismatches are obvious)
///
/// ## Testing Strategy for Views
///
/// ### 1. Data-Driven View Testing (This File)
/// Test the data transformations that views depend on. If data is correct,
/// views will render correctly (assuming views are built correctly).
///
/// ### 2. Preview-Based Testing
/// Use Xcode Previews to visually verify UI across:
/// - Different devices (iPhone, iPad, Watch)
/// - Light/Dark mode
/// - Different accessibility settings
/// - Various data states (empty, full, edge cases)
///
/// ### 3. UI Tests (XCUITest)
/// For critical user flows, write UI tests that:
/// - Launch the app
/// - Interact with UI elements
/// - Verify expected outcomes
///
/// ### 4. Snapshot Testing (optional, requires additional setup)
/// Libraries like swift-snapshot-testing can capture view renders
/// and compare against reference images.
final class ViewDataTests: XCTestCase {

    // MARK: - Test Fixtures

    private let calendar = Calendar.current

    // MARK: - MoonCalendar View Data Tests

    func testMoonCalendarReceivesCorrectMonthData() {
        /*
         * MoonCalendar view depends on MonthData to render the grid
         * Verify the data structure is suitable for the 7-column grid
         */
        let monthData = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15"),
            includeOverlap: true
        )

        /*
         * Calendar should have enough cells for a complete grid
         * (5 or 6 rows × 7 columns)
         */
        let validGridSizes = [35, 42]
        XCTAssertTrue(validGridSizes.contains(monthData.monthCalendar.count),
                     "Calendar grid should be 35 or 42 cells")

        /*
         * First row should start with Sunday (or include leading overlaps)
         */
        let leadingOverlaps = monthData.monthCalendar.prefix(monthData.monthStartWeekdayIndex)
        for day in leadingOverlaps {
            XCTAssertTrue(day.isOverlap, "Leading cells should be overlaps for proper grid alignment")
        }
    }

    func testMoonCalendarNavigationDataConsistency() {
        /*
         * Test that navigating months produces consistent data
         */
        let june2025 = dateFromString("2025-06-15")
        let july2025 = dateFromString("2025-07-15")

        let juneData = MoonCalendarGenerator.buildMonthData(for: june2025)
        let julyData = MoonCalendarGenerator.buildMonthData(for: july2025)

        XCTAssertEqual(juneData.monthNumber, 6)
        XCTAssertEqual(julyData.monthNumber, 7)
        XCTAssertEqual(juneData.year, julyData.year)

        /*
         * Last day of June's grid should connect to July's first day
         */
        let juneLastBuiltDay = juneData.monthBuilt.last!
        let julyFirstBuiltDay = julyData.monthBuilt.first!

        let juneLastDate = juneLastBuiltDay.date
        let julyFirstDate = julyFirstBuiltDay.date

        let daysBetween = calendar.dateComponents([.day], from: juneLastDate, to: julyFirstDate).day!
        XCTAssertEqual(daysBetween, 1, "Months should be contiguous")
    }

    // MARK: - DayCard View Data Tests

    func testDayCardPhaseDataIsComplete() {
        /*
         * DayCard displays phase information - verify all needed data exists
         */
        let testDate = dateFromString("2025-06-15")
        let phase = MoonCalendarGenerator.phase(for: testDate)

        /*
         * DayCard needs these for rendering
         */
        XCTAssertFalse(phase.primary.name.isEmpty, "Phase name needed for header")
        XCTAssertFalse(phase.primary.description.isEmpty, "Description needed for subtitle")
        XCTAssertFalse(phase.primary.planting.isEmpty, "Planting guidance for detail section")
        XCTAssertFalse(phase.primary.fishing.isEmpty, "Fishing guidance for detail section")
        XCTAssertGreaterThanOrEqual(phase.primary.day, 1, "Day number for moon image")
        XCTAssertLessThanOrEqual(phase.primary.day, 30, "Day number for moon image")
    }

    func testDayCardTransitionDayHasBothPhases() {
        /*
         * Transition day cards show both primary and secondary phases
         */
        let monthData = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-02-15"),
            includeOverlap: false
        )

        let transitionDays = monthData.monthBuilt.filter { $0.phase.isTransitionDay }

        for moonDay in transitionDays {
            XCTAssertNotNil(moonDay.phase.secondary,
                          "Transition day must have secondary phase for split display")

            /*
             * Primary and secondary should be adjacent phases
             */
            let primary = moonDay.phase.primary.day
            let secondary = moonDay.phase.secondary!.day

            let isAdjacent = secondary == primary + 1 || (primary == 30 && secondary == 1)
            XCTAssertTrue(isAdjacent,
                         "Transition phases should be adjacent: \(primary) and \(secondary)")
        }
    }

    // MARK: - PhaseGroups View Data Tests

    func testPhaseGroupsReceivesThreeRows() {
        /*
         * PhaseGroups view expects exactly 3 rows for Hoʻonui, Poepoe, Emi
         */
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(
            monthData: monthData,
            activeDate: testDate
        )

        XCTAssertEqual(rows.count, 3, "PhaseGroups expects 3 rows")
    }

    func testPhaseGroupsRowsHaveCorrectDayCounts() {
        /*
         * Each group has a specific number of days for the progress indicator
         */
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(
            monthData: monthData,
            activeDate: testDate
        )

        /*
         * Hoʻonui: days 1-10 (10 days)
         * Poepoe: days 11-16 (6 days)
         * Emi: days 17-30 (14 days)
         */
        XCTAssertEqual(rows[0].days.count, 10, "Hoʻonui should have 10 indicators")
        XCTAssertEqual(rows[1].days.count, 6, "Poepoe should have 6 indicators")
        XCTAssertEqual(rows[2].days.count, 14, "Emi should have 14 indicators")
    }

    func testPhaseGroupsFillStateMatchesActiveDay() {
        /*
         * The fill state of indicators should reflect progress through the month
         */
        let monthData = MoonCalendarGenerator.buildMonthData(for: dateFromString("2025-06-15"))

        /*
         * Find a day with lunar phase 14 to test mid-month
         */
        for moonDay in monthData.monthBuilt {
            if moonDay.phase.primary.day == 14 {
                let rows = MoonCalendarGenerator.buildGroupRows(
                    monthData: monthData,
                    activeDate: moonDay.date
                )

                /*
                 * Count total filled indicators
                 */
                let totalFilled = rows.reduce(0) { sum, row in
                    sum + row.days.filter { $0.isFilled }.count
                }

                XCTAssertEqual(totalFilled, 14,
                              "14 indicators should be filled up to lunar day 14")
                return
            }
        }
    }

    func testPhaseGroupsActiveGroupIsCorrect() {
        /*
         * Only one group should be marked as active based on current lunar day
         */
        let monthData = MoonCalendarGenerator.buildMonthData(for: dateFromString("2025-06-15"))

        /*
         * Test across different phases
         */
        let testCases: [(Int, String)] = [
            (5, "Hoʻonui"),   // Day 5 is in Hoʻonui
            (14, "Poepoe"),   // Day 14 is in Poepoe
            (25, "Emi")       // Day 25 is in Emi
        ]

        for (targetDay, expectedGroup) in testCases {
            for moonDay in monthData.monthBuilt {
                if moonDay.phase.primary.day == targetDay {
                    let rows = MoonCalendarGenerator.buildGroupRows(
                        monthData: monthData,
                        activeDate: moonDay.date
                    )

                    let activeRow = rows.first { $0.isActiveGroup }
                    XCTAssertEqual(activeRow?.name, expectedGroup,
                                  "Day \(targetDay) should have \(expectedGroup) as active")
                    break
                }
            }
        }
    }

    // MARK: - DateHeader View Data Tests

    func testDateHeaderHawaiianLocalization() {
        /*
         * DateHeader shows Hawaiian weekday and month names
         */
        let testDate = dateFromString("2025-06-15")

        let weekday = HawaiianLocalization.weekday(for: testDate)
        let month = HawaiianLocalization.month(for: testDate)

        XCTAssertNotNil(weekday, "Hawaiian weekday should be available")
        XCTAssertNotNil(month, "Hawaiian month should be available")
        XCTAssertFalse(weekday!.isEmpty)
        XCTAssertFalse(month!.isEmpty)
    }

    // MARK: - MoonImage View Data Tests

    func testMoonImageDayInValidRange() {
        /*
         * MoonImage uses day number (1-30) to select the correct icon
         */
        let testDates = (0..<30).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: offset, to: dateFromString("2025-06-01"))
        }

        for testDate in testDates {
            let phase = MoonCalendarGenerator.phase(for: testDate)
            let day = phase.primary.day

            XCTAssertGreaterThanOrEqual(day, 1, "Day must be >= 1 for icon selection")
            XCTAssertLessThanOrEqual(day, 30, "Day must be <= 30 for icon selection")
        }
    }

    // MARK: - Widget Display Mode Tests

    func testPhaseDataSuitableForSmallWidget() {
        /*
         * Small widget needs compact data
         */
        let phase = MoonCalendarGenerator.phase(for: dateFromString("2025-06-15"))

        /*
         * Name should be short enough for small display
         */
        XCTAssertLessThanOrEqual(phase.primary.name.count, 15,
                                "Phase name should be short for widget display")
    }

    func testMonthDataSuitableForWidget() {
        /*
         * Widget may show multiple days - verify data is appropriate
         */
        let monthData = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15"),
            includeOverlap: false
        )

        /*
         * Each day should have complete phase info for widget rendering
         */
        for moonDay in monthData.monthBuilt.prefix(7) {  // Check first week
            XCTAssertFalse(moonDay.phase.primary.name.isEmpty)
            XCTAssertGreaterThanOrEqual(moonDay.day, 1)
            XCTAssertLessThanOrEqual(moonDay.day, 30)
        }
    }

    // MARK: - Cross-Platform Display Tests

    func testDataConsistencyAcrossPlatforms() {
        /*
         * Data should be identical regardless of which platform renders it
         * This ensures iOS, watchOS, and macOS show the same information
         */
        let testDate = dateFromString("2025-06-15")

        /*
         * Generate data multiple times - should be deterministic
         */
        let phase1 = MoonCalendarGenerator.phase(for: testDate)
        let phase2 = MoonCalendarGenerator.phase(for: testDate)

        XCTAssertEqual(phase1.primary.day, phase2.primary.day)
        XCTAssertEqual(phase1.primary.name, phase2.primary.name)
        XCTAssertEqual(phase1.isTransitionDay, phase2.isTransitionDay)

        let monthData1 = MoonCalendarGenerator.buildMonthData(for: testDate)
        let monthData2 = MoonCalendarGenerator.buildMonthData(for: testDate)

        XCTAssertEqual(monthData1.monthNumber, monthData2.monthNumber)
        XCTAssertEqual(monthData1.monthDays, monthData2.monthDays)
        XCTAssertEqual(monthData1.monthBuilt.count, monthData2.monthBuilt.count)
    }

    // MARK: - Accessibility Data Tests

    func testPhaseDataSupportsAccessibility() {
        /*
         * Views provide accessibility labels using phase data
         * Verify the data is suitable for screen readers
         */
        let phase = MoonCalendarGenerator.phase(for: dateFromString("2025-06-15"))

        /*
         * Name should be pronounceable
         */
        XCTAssertFalse(phase.primary.name.isEmpty, "Name needed for accessibility label")

        /*
         * Description should provide context
         */
        XCTAssertFalse(phase.primary.description.isEmpty,
                      "Description needed for accessibility value")

        /*
         * Group info helps users understand position in cycle
         */
        XCTAssertFalse(phase.primary.groupName.isEmpty,
                      "Group name helps accessibility context")
    }

    func testGroupRowDataSupportsAccessibility() {
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(
            monthData: monthData,
            activeDate: testDate
        )

        for row in rows {
            /*
             * Row name for accessibility label
             */
            XCTAssertFalse(row.name.isEmpty)

            /*
             * Can calculate progress for accessibility value
             */
            let filledCount = row.days.filter { $0.isFilled }.count
            let totalCount = row.days.count
            XCTAssertGreaterThan(totalCount, 0, "Should have days to report progress")

            /*
             * Progress calculation should be valid
             */
            XCTAssertGreaterThanOrEqual(filledCount, 0)
            XCTAssertLessThanOrEqual(filledCount, totalCount)
        }
    }
}
