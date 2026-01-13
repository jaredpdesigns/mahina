import XCTest
@testable import MahinaAssets

/// Tests for data model types to ensure correct initialization, computed properties,
/// and protocol conformances (Hashable, Identifiable, etc.)
///
/// These tests verify the structural integrity of the model layer that supports
/// the Hawaiian lunar calendar views.
final class ModelTests: XCTestCase {

    // MARK: - MoonPhase Tests

    func testMoonPhaseInitialization() {
        let phase = MoonPhase(
            day: 14,
            name: "Akua",
            description: "Full moon, sacred to the gods",
            planting: "Favorable for planting",
            fishing: "Good night for fishing",
            gridPosition: 15,
            groupName: "Poepoe",
            groupDescription: "Full moon phases"
        )

        XCTAssertEqual(phase.day, 14)
        XCTAssertEqual(phase.name, "Akua")
        XCTAssertEqual(phase.description, "Full moon, sacred to the gods")
        XCTAssertEqual(phase.planting, "Favorable for planting")
        XCTAssertEqual(phase.fishing, "Good night for fishing")
        XCTAssertEqual(phase.gridPosition, 15)
        XCTAssertEqual(phase.groupName, "Poepoe")
        XCTAssertEqual(phase.groupDescription, "Full moon phases")
    }

    func testMoonPhaseIdentifiableConformance() {
        let phase1 = MoonCalendarGenerator.moonPhase(for: 14)
        let phase2 = MoonCalendarGenerator.moonPhase(for: 14)

        /*
         * Each instance should have a unique ID (UUID)
         */
        XCTAssertNotEqual(phase1.id, phase2.id,
                         "Different instances should have different IDs")
    }

    func testMoonPhaseHashableConformance() {
        let phase1 = MoonCalendarGenerator.moonPhase(for: 14)
        let phase2 = MoonCalendarGenerator.moonPhase(for: 14)

        /*
         * Same day phases should be equal (same content)
         */
        XCTAssertEqual(phase1.day, phase2.day)
        XCTAssertEqual(phase1.name, phase2.name)

        /*
         * Can be used in Sets
         */
        var phaseSet = Set<MoonPhase>()
        phaseSet.insert(phase1)
        phaseSet.insert(phase2)

        /*
         * Both should be in set since they have different UUIDs
         */
        XCTAssertEqual(phaseSet.count, 2)
    }

    // MARK: - PhaseResult Tests

    func testPhaseResultNonTransitionDay() {
        let primary = MoonCalendarGenerator.moonPhase(for: 14)
        let result = PhaseResult(primary: primary)

        XCTAssertEqual(result.primary.day, 14)
        XCTAssertNil(result.secondary, "Non-transition day should have no secondary")
        XCTAssertFalse(result.isTransitionDay, "Should not be a transition day")
    }

    func testPhaseResultTransitionDay() {
        let primary = MoonCalendarGenerator.moonPhase(for: 13)
        let secondary = MoonCalendarGenerator.moonPhase(for: 14)
        let result = PhaseResult(primary: primary, secondary: secondary)

        XCTAssertEqual(result.primary.day, 13)
        XCTAssertEqual(result.secondary?.day, 14)
        XCTAssertTrue(result.isTransitionDay, "Should be a transition day")
    }

    func testPhaseResultHashableConformance() {
        let primary1 = MoonCalendarGenerator.moonPhase(for: 14)
        let primary2 = MoonCalendarGenerator.moonPhase(for: 14)

        let result1 = PhaseResult(primary: primary1)
        let result2 = PhaseResult(primary: primary2)

        /*
         * Results with same primary day data should be usable in sets
         */
        var resultSet = Set<PhaseResult>()
        resultSet.insert(result1)
        resultSet.insert(result2)

        XCTAssertEqual(resultSet.count, 2, "Different instances go in set separately")
    }

    // MARK: - MoonDay Tests

    func testMoonDayInitialization() {
        let testDate = dateFromString("2025-06-15")
        let phase = MoonCalendarGenerator.phase(for: testDate)
        let moonDay = MoonDay(
            date: testDate,
            calendarDay: 15,
            isOverlap: false,
            phase: phase
        )

        XCTAssertEqual(moonDay.calendarDay, 15)
        XCTAssertFalse(moonDay.isOverlap)
        XCTAssertEqual(moonDay.date, testDate)
    }

    func testMoonDayConvenienceProperty() {
        let testDate = dateFromString("2025-06-15")
        let phase = MoonCalendarGenerator.phase(for: testDate)
        let moonDay = MoonDay(
            date: testDate,
            calendarDay: 15,
            isOverlap: false,
            phase: phase
        )

        /*
         * The `day` convenience property should return the primary phase day
         */
        XCTAssertEqual(moonDay.day, phase.primary.day)
    }

    func testMoonDayIdentifiableConformance() {
        let testDate = dateFromString("2025-06-15")
        let phase = MoonCalendarGenerator.phase(for: testDate)

        let moonDay1 = MoonDay(date: testDate, calendarDay: 15, isOverlap: false, phase: phase)
        let moonDay2 = MoonDay(date: testDate, calendarDay: 15, isOverlap: false, phase: phase)

        XCTAssertNotEqual(moonDay1.id, moonDay2.id,
                         "Different instances should have different IDs")
    }

    // MARK: - MonthData Tests

    func testMonthDataInitialization() {
        let monthData = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15"),
            includeOverlap: false
        )

        XCTAssertEqual(monthData.monthNumber, 6)
        XCTAssertEqual(monthData.year, 2025)
        XCTAssertEqual(monthData.monthDays, 30)  // June has 30 days
        XCTAssertFalse(monthData.monthName.isEmpty)
    }

    func testMonthDataIdentifiableConformance() {
        let monthData1 = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15")
        )
        let monthData2 = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15")
        )

        XCTAssertNotEqual(monthData1.id, monthData2.id,
                         "Different instances should have different UUIDs")
    }

    func testMonthDataHashableConformance() {
        let monthData1 = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15")
        )
        let monthData2 = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-07-15")
        )

        var dataSet = Set<MonthData>()
        dataSet.insert(monthData1)
        dataSet.insert(monthData2)

        XCTAssertEqual(dataSet.count, 2, "Different months should be in set")
    }

    // MARK: - MoonGroup Tests

    func testMoonGroupHoonuiMetadata() {
        let metadata = MoonGroup.hoonui.metadata

        XCTAssertEqual(metadata.name, "Hoʻonui")
        XCTAssertFalse(metadata.description.isEmpty)
        XCTAssertEqual(metadata.englishMeaning, "to grow bigger")
    }

    func testMoonGroupPoepoeMetadata() {
        let metadata = MoonGroup.poepoe.metadata

        XCTAssertEqual(metadata.name, "Poepoe")
        XCTAssertFalse(metadata.description.isEmpty)
        XCTAssertEqual(metadata.englishMeaning, "round")
    }

    func testMoonGroupEmiMetadata() {
        let metadata = MoonGroup.emi.metadata

        XCTAssertEqual(metadata.name, "Emi")
        XCTAssertFalse(metadata.description.isEmpty)
        XCTAssertEqual(metadata.englishMeaning, "to decrease")
    }

    func testAllGroupsHaveUniqueNames() {
        let groups: [MoonGroup] = [.hoonui, .poepoe, .emi]
        let names = groups.map { $0.metadata.name }
        let uniqueNames = Set(names)

        XCTAssertEqual(uniqueNames.count, 3, "All groups should have unique names")
    }

    // MARK: - MoonGroupRow Tests

    func testMoonGroupRowInitialization() {
        let days = [
            MoonGroupRow.Day(lunarDay: 1, calendarDay: 5, isFilled: true),
            MoonGroupRow.Day(lunarDay: 2, calendarDay: 6, isFilled: true),
            MoonGroupRow.Day(lunarDay: 3, calendarDay: 7, isFilled: false)
        ]

        let row = MoonGroupRow(
            name: "Test Group",
            description: "Test description",
            englishMeaning: "test meaning",
            days: days,
            isActiveGroup: true
        )

        XCTAssertEqual(row.name, "Test Group")
        XCTAssertEqual(row.description, "Test description")
        XCTAssertEqual(row.englishMeaning, "test meaning")
        XCTAssertEqual(row.days.count, 3)
        XCTAssertTrue(row.isActiveGroup)
    }

    func testMoonGroupRowDayInitialization() {
        let day = MoonGroupRow.Day(lunarDay: 14, calendarDay: 20, isFilled: true)

        XCTAssertEqual(day.lunarDay, 14)
        XCTAssertEqual(day.calendarDay, 20)
        XCTAssertTrue(day.isFilled)
    }

    func testMoonGroupRowDayWithNilCalendarDay() {
        /*
         * calendarDay can be nil when lunar day doesn't fall in current month
         */
        let day = MoonGroupRow.Day(lunarDay: 30, calendarDay: nil, isFilled: false)

        XCTAssertEqual(day.lunarDay, 30)
        XCTAssertNil(day.calendarDay)
        XCTAssertFalse(day.isFilled)
    }

    func testMoonGroupRowIdentifiableConformance() {
        let row1 = MoonGroupRow(
            name: "Test",
            description: "Test",
            englishMeaning: "test",
            days: [],
            isActiveGroup: false
        )
        let row2 = MoonGroupRow(
            name: "Test",
            description: "Test",
            englishMeaning: "test",
            days: [],
            isActiveGroup: false
        )

        XCTAssertNotEqual(row1.id, row2.id, "Different instances have different IDs")
    }

    func testMoonGroupRowDayIdentifiableConformance() {
        let day1 = MoonGroupRow.Day(lunarDay: 14, calendarDay: 20, isFilled: true)
        let day2 = MoonGroupRow.Day(lunarDay: 14, calendarDay: 20, isFilled: true)

        XCTAssertNotEqual(day1.id, day2.id, "Different day instances have different IDs")
    }

    // MARK: - Integration Tests

    func testGeneratedGroupRowsAreValid() {
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(
            monthData: monthData,
            activeDate: testDate
        )

        XCTAssertEqual(rows.count, 3, "Should have 3 group rows")

        /*
         * Verify structure of each row
         */
        for row in rows {
            XCTAssertFalse(row.name.isEmpty)
            XCTAssertFalse(row.description.isEmpty)
            XCTAssertFalse(row.englishMeaning.isEmpty)
            XCTAssertGreaterThan(row.days.count, 0)

            for day in row.days {
                XCTAssertGreaterThanOrEqual(day.lunarDay, 1)
                XCTAssertLessThanOrEqual(day.lunarDay, 30)
            }
        }
    }

    func testMoonDayInMonthDataIsValid() {
        let monthData = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15"),
            includeOverlap: false
        )

        for moonDay in monthData.monthBuilt {
            XCTAssertFalse(moonDay.isOverlap, "Built month should not have overlaps")
            XCTAssertGreaterThanOrEqual(moonDay.calendarDay, 1)
            XCTAssertLessThanOrEqual(moonDay.calendarDay, 30)
            XCTAssertGreaterThanOrEqual(moonDay.day, 1)
            XCTAssertLessThanOrEqual(moonDay.day, 30)
        }
    }

    func testOverlapDaysAreMarkedCorrectly() {
        let monthData = MoonCalendarGenerator.buildMonthData(
            for: dateFromString("2025-06-15"),
            includeOverlap: true
        )

        /*
         * Leading days (before month start) should be overlaps
         */
        let leadingDays = monthData.monthCalendar.prefix(monthData.monthStartWeekdayIndex)
        for day in leadingDays {
            XCTAssertTrue(day.isOverlap, "Leading days should be marked as overlap")
        }

        /*
         * Days in the actual month should not be overlaps
         */
        let monthDays = monthData.monthCalendar.dropFirst(monthData.monthStartWeekdayIndex).prefix(monthData.monthDays)
        for day in monthDays {
            XCTAssertFalse(day.isOverlap, "Month days should not be marked as overlap")
        }
    }
}
