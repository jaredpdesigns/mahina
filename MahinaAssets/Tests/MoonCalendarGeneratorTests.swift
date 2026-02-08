import XCTest

@testable import MahinaAssets

/// Comprehensive tests for MoonCalendarGenerator - the core lunar calculation engine.
///
/// These tests verify:
/// - Lunar age calculations based on synodic month
/// - Phase mapping from continuous age to discrete 30-day system
/// - Month data generation for calendar grids
/// - Group row generation for phase progress UI
/// - Transition day detection and handling
/// - Edge cases around month/year boundaries
final class MoonCalendarGeneratorTests: XCTestCase {
    
    // MARK: - Test Fixtures
    
    private let calendar = Calendar.current
    
    // MARK: - Lunar Age Calculation Tests
    
    func testLunarAgeReturnsValueInValidRange() {
        /*
         * Lunar age should always be between 0 and synodic month length (~29.53 days)
         */
        let testDates = [
            dateFromString("2024-01-11"),  // Reference new moon
            dateFromString("2024-06-15"),
            dateFromString("2025-03-01"),
            dateFromString("2025-12-31"),
            dateFromString("2026-01-01"),
        ]
        
        for testDate in testDates {
            let age = MoonCalendarGenerator.lunarAge(for: testDate)
            XCTAssertGreaterThanOrEqual(age, 0, "Lunar age should be >= 0 for \(testDate)")
            XCTAssertLessThan(
                age, 29.530588, "Lunar age should be < synodic length for \(testDate)")
        }
    }
    
    func testLunarAgeAtReferenceNewMoonIsNearZero() {
        /*
         * The reference new moon (2024-01-11) should have age near 0
         */
        let referenceDate = dateFromString("2024-01-11")
        let age = MoonCalendarGenerator.lunarAge(for: referenceDate)
        
        XCTAssertLessThan(age, 1.0, "Age at reference new moon should be near 0")
    }
    
    func testLunarAgeProgressesCorrectlyOverDays() {
        /*
         * Age should increase by ~1 for each day
         */
        let startDate = dateFromString("2025-06-01")
        let startAge = MoonCalendarGenerator.lunarAge(for: startDate)
        
        for dayOffset in 1...5 {
            let testDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            let testAge = MoonCalendarGenerator.lunarAge(for: testDate)
            
            /*
             * Handle wraparound at synodic month boundary
             */
            let expectedAge = (startAge + Double(dayOffset)).truncatingRemainder(
                dividingBy: 29.530588)
            let normalizedExpected = expectedAge >= 0 ? expectedAge : expectedAge + 29.530588
            
            XCTAssertEqual(
                testAge, normalizedExpected, accuracy: 0.1,
                "Age should progress by ~\(dayOffset) days from start")
        }
    }
    
    func testLunarAgeWrapsAtSynodicBoundary() {
        /*
         * After ~29.53 days, the age should wrap back near 0
         */
        let startDate = dateFromString("2025-01-01")
        let startAge = MoonCalendarGenerator.lunarAge(for: startDate)
        
        /*
         * Add 30 days - should be close to startAge + ~0.47 days (wrapped)
         */
        let laterDate = calendar.date(byAdding: .day, value: 30, to: startDate)!
        let laterAge = MoonCalendarGenerator.lunarAge(for: laterDate)
        
        let expectedAge = (startAge + 30).truncatingRemainder(dividingBy: 29.530588)
        XCTAssertEqual(laterAge, expectedAge, accuracy: 0.1, "Age should wrap at synodic boundary")
    }
    
    // MARK: - Phase Lookup Tests
    
    func testMoonPhaseReturnsValidPhaseForAllDays() {
        /*
         * All lunar days 1-30 should return valid phase data
         */
        for day in 1...30 {
            let phase = MoonCalendarGenerator.moonPhase(for: day)
            
            XCTAssertEqual(phase.day, day, "Phase day should match input")
            XCTAssertFalse(phase.name.isEmpty, "Phase name should not be empty for day \(day)")
            XCTAssertFalse(phase.description.isEmpty, "Phase description should not be empty")
            XCTAssertFalse(phase.planting.isEmpty, "Planting guidance should not be empty")
            XCTAssertFalse(phase.fishing.isEmpty, "Fishing guidance should not be empty")
        }
    }
    
    func testMoonPhaseNormalizesOutOfRangeValues() {
        /*
         * Values outside 1-30 should be clamped
         */
        let phaseForZero = MoonCalendarGenerator.moonPhase(for: 0)
        XCTAssertEqual(phaseForZero.day, 1, "Day 0 should be normalized to 1")
        
        let phaseForNegative = MoonCalendarGenerator.moonPhase(for: -5)
        XCTAssertEqual(phaseForNegative.day, 1, "Negative day should be normalized to 1")
        
        let phaseFor31 = MoonCalendarGenerator.moonPhase(for: 31)
        XCTAssertEqual(phaseFor31.day, 30, "Day 31 should be normalized to 30")
        
        let phaseFor100 = MoonCalendarGenerator.moonPhase(for: 100)
        XCTAssertEqual(phaseFor100.day, 30, "Day 100 should be normalized to 30")
    }
    
    func testMoonPhaseGroupAssignment() {
        /*
         * Verify correct group assignment for each phase range (anahulu system)
         */
        let hoonuiPhases = (1...10).map { MoonCalendarGenerator.moonPhase(for: $0) }
        let poepoePhases = (11...20).map { MoonCalendarGenerator.moonPhase(for: $0) }
        let emiPhases = (21...30).map { MoonCalendarGenerator.moonPhase(for: $0) }
        
        for phase in hoonuiPhases {
            XCTAssertEqual(phase.groupName, "Hoʻonui", "Days 1-10 should be in Hoʻonui group")
        }
        
        for phase in poepoePhases {
            XCTAssertEqual(phase.groupName, "Poepoe", "Days 11-20 should be in Poepoe group")
        }
        
        for phase in emiPhases {
            XCTAssertEqual(phase.groupName, "Emi", "Days 21-30 should be in Emi group")
        }
    }
    
    func testKeyPhaseNames() {
        /*
         * Verify the culturally significant phase names
         */
        let hilo = MoonCalendarGenerator.moonPhase(for: 1)
        XCTAssertEqual(hilo.name, "Hilo", "Day 1 should be Hilo (new moon)")
        
        let akua = MoonCalendarGenerator.moonPhase(for: 14)
        XCTAssertEqual(akua.name, "Akua", "Day 14 should be Akua (full moon)")
        
        let hoku = MoonCalendarGenerator.moonPhase(for: 15)
        XCTAssertEqual(hoku.name, "Hoku", "Day 15 should be Hoku (brightest full)")
        
        let muku = MoonCalendarGenerator.moonPhase(for: 30)
        XCTAssertEqual(muku.name, "Muku", "Day 30 should be Muku (dark moon)")
    }
    
    // MARK: - Phase For Date Tests
    
    func testPhaseForDateReturnsValidResult() {
        let testDate = dateFromString("2025-06-15")
        let result = MoonCalendarGenerator.phase(for: testDate)
        
        XCTAssertNotNil(result.primary, "Primary phase should always be set")
        XCTAssertGreaterThanOrEqual(result.primary.day, 1)
        XCTAssertLessThanOrEqual(result.primary.day, 30)
    }
    
    func testPhaseForDateConsistencyAcrossMonth() {
        /*
         * Phases should progress through a month without skipping days.
         * With round+clamp, consecutive days generally advance by 0 or 1,
         * with occasional same-phase days near the Hilo boundary (handled
         * by new-moon transition detection). Transition days may show a
         * phase that matches the previous day's phase (the transition's
         * ending phase) but this is expected behavior.
         */
        let monthStart = dateFromString("2025-03-01")
        var previousPhase = -1
        var phaseChanges = 0
        
        for dayOffset in 0..<28 {
            let testDate = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
            let result = MoonCalendarGenerator.phase(for: testDate)
            let currentPhase = result.primary.day
            
            if previousPhase != -1 {
                let validProgression =
                currentPhase == previousPhase
                || currentPhase == previousPhase + 1
                || (previousPhase == 30 && currentPhase == 1)
                
                XCTAssertTrue(
                    validProgression,
                    "Phase should stay same or advance by 1: \(previousPhase) -> \(currentPhase)")
                
                if currentPhase != previousPhase {
                    phaseChanges += 1
                }
            }
            previousPhase = currentPhase
        }
        
        /*
         * Roughly 27-28 phase changes expected over 28 days.
         * The synodic month is ~29.53 days, so in a 28-day window
         * we see about 27 distinct phase transitions.
         */
        XCTAssertTrue(
            phaseChanges >= 25 && phaseChanges <= 28,
            "Should see roughly 25-28 phase changes in 28 days, got \(phaseChanges)")
    }
    
    // MARK: - Transition Day Tests
    
    func testTransitionDayHasSecondaryPhase() {
        /*
         * Find a transition day and verify it has secondary phase
         */
        let monthDate = dateFromString("2025-02-01")
        
        for dayOffset in 0..<28 {
            let testDate = calendar.date(byAdding: .day, value: dayOffset, to: monthDate)!
            let result = MoonCalendarGenerator.phase(for: testDate)
            
            if result.isTransitionDay {
                XCTAssertNotNil(result.secondary, "Transition day should have secondary phase")
                XCTAssertNotEqual(
                    result.primary.day, result.secondary?.day,
                    "Primary and secondary should be different phases")
                return
            }
        }
        
        /*
         * Note: Some months may not have transition days due to the "first per month" rule
         */
    }
    
    func testTransitionDayPhaseOrdering() {
        /*
         * On transition days, primary should be the "ending" phase (morning)
         * and secondary should be the "beginning" phase (evening)
         */
        let testDates = [
            dateFromString("2025-02-27")  // Known transition from analysis tests
        ]
        
        for testDate in testDates {
            let result = MoonCalendarGenerator.phase(for: testDate)
            
            if result.isTransitionDay {
                /*
                 * Primary (ending) should logically precede secondary (beginning)
                 * in the 30-day cycle, with wraparound at 30->1
                 */
                let primary = result.primary.day
                let secondary = result.secondary!.day
                
                let isValidTransition =
                secondary == primary + 1 || (primary == 30 && secondary == 1)
                
                XCTAssertTrue(
                    isValidTransition,
                    "Transition should be consecutive: \(primary) -> \(secondary)")
            }
        }
    }
    
    func testMaxOneTransitionDayPerMonth() {
        /*
         * Only ONE transition day should be flagged per calendar month
         */
        let monthDates = (1...12).map { String(format: "2025-%02d-15", $0) }
        for (index, dateString) in monthDates.enumerated() {
            let monthDate = dateFromString(dateString)
            let month = index + 1
            let monthData = MoonCalendarGenerator.buildMonthData(
                for: monthDate, includeOverlap: false)
            
            let transitionDays = monthData.monthBuilt.filter { $0.phase.isTransitionDay }
            
            XCTAssertLessThanOrEqual(
                transitionDays.count, 1,
                "Month \(month) should have at most 1 transition day, found \(transitionDays.count)"
            )
        }
    }
    
    // MARK: - Month Data Generation Tests
    
    func testBuildMonthDataWithoutOverlap() {
        let testDate = dateFromString("2025-03-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate, includeOverlap: false)
        
        XCTAssertEqual(monthData.monthNumber, 3, "Month number should be 3")
        XCTAssertEqual(monthData.year, 2025, "Year should be 2025")
        XCTAssertEqual(monthData.monthDays, 31, "March has 31 days")
        XCTAssertEqual(monthData.monthBuilt.count, 31, "Should have 31 days in built month")
        XCTAssertEqual(monthData.monthCalendar.count, 31, "Without overlap, calendar equals built")
    }
    
    func testBuildMonthDataWithOverlap() {
        let testDate = dateFromString("2025-03-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate, includeOverlap: true)
        
        /*
         * Calendar with overlap should be 35 or 42 cells (5 or 6 weeks)
         */
        let validLengths = [35, 42]
        XCTAssertTrue(
            validLengths.contains(monthData.monthCalendar.count),
            "Calendar should be 35 or 42 cells, got \(monthData.monthCalendar.count)")
        
        /*
         * monthBuilt should still be just the current month
         */
        XCTAssertEqual(
            monthData.monthBuilt.count, 31, "Built month should only have current month days")
        
        /*
         * Leading overlap days should be marked as overlap
         */
        let leadingOverlap = monthData.monthCalendar.prefix(while: { $0.isOverlap })
        XCTAssertEqual(
            leadingOverlap.count, monthData.monthStartWeekdayIndex,
            "Leading overlap should match month start index")
    }
    
    func testMonthDataForFebruary() {
        /*
         * Test leap year and non-leap year February
         */
        let feb2024 = dateFromString("2024-02-15")  // Leap year
        let feb2025 = dateFromString("2025-02-15")  // Non-leap year
        
        let data2024 = MoonCalendarGenerator.buildMonthData(for: feb2024, includeOverlap: false)
        let data2025 = MoonCalendarGenerator.buildMonthData(for: feb2025, includeOverlap: false)
        
        XCTAssertEqual(data2024.monthDays, 29, "2024 February should have 29 days (leap year)")
        XCTAssertEqual(data2025.monthDays, 28, "2025 February should have 28 days (non-leap year)")
    }
    
    func testMonthDataDayDatesAreCorrect() {
        let testDate = dateFromString("2025-06-01")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate, includeOverlap: false)
        
        for moonDay in monthData.monthBuilt {
            let dayOfMonth = calendar.component(.day, from: moonDay.date)
            XCTAssertEqual(
                dayOfMonth, moonDay.calendarDay,
                "Calendar day should match date component")
            
            let monthOfDay = calendar.component(.month, from: moonDay.date)
            XCTAssertEqual(monthOfDay, 6, "All days should be in June")
        }
    }
    
    // MARK: - Calendar Helper Tests
    
    func testStartOfMonthIndex() {
        /*
         * Test known dates with known weekdays
         */
        let sunday = dateFromString("2025-06-01")  // June 1, 2025 is Sunday
        let monday = dateFromString("2025-09-01")  // September 1, 2025 is Monday
        let saturday = dateFromString("2025-03-01")  // March 1, 2025 is Saturday
        
        XCTAssertEqual(
            MoonCalendarGenerator.startOfMonthIndex(for: sunday), 0,
            "Sunday should have index 0")
        XCTAssertEqual(
            MoonCalendarGenerator.startOfMonthIndex(for: monday), 1,
            "Monday should have index 1")
        XCTAssertEqual(
            MoonCalendarGenerator.startOfMonthIndex(for: saturday), 6,
            "Saturday should have index 6")
    }
    
    func testDaysInMonth() {
        let testCases: [(String, Int)] = [
            ("2025-01-15", 31),  // January
            ("2025-02-15", 28),  // February (non-leap)
            ("2024-02-15", 29),  // February (leap)
            ("2025-04-15", 30),  // April
            ("2025-06-15", 30),  // June
            ("2025-12-15", 31),  // December
        ]
        
        for (dateString, expectedDays) in testCases {
            let testDate = dateFromString(dateString)
            let days = MoonCalendarGenerator.daysInMonth(for: testDate)
            XCTAssertEqual(
                days, expectedDays,
                "\(dateString) month should have \(expectedDays) days")
        }
    }
    
    func testMonthName() {
        let testDate = dateFromString("2025-07-15")
        let name = MoonCalendarGenerator.monthName(for: testDate)
        
        /*
         * Month name should be localized, so we just check it's not empty
         * and contains expected substring
         */
        XCTAssertFalse(name.isEmpty, "Month name should not be empty")
        XCTAssertTrue(name.lowercased().contains("jul"), "July month name should contain 'jul'")
    }
    
    // MARK: - Group Row Generation Tests
    
    func testBuildGroupRowsReturnsThreeGroups() {
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: testDate)
        
        XCTAssertEqual(rows.count, 3, "Should have exactly 3 group rows")
        XCTAssertEqual(rows[0].name, "Hoʻonui")
        XCTAssertEqual(rows[1].name, "Poepoe")
        XCTAssertEqual(rows[2].name, "Emi")
    }
    
    func testBuildGroupRowsDayCount() {
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: testDate)
        
        XCTAssertEqual(rows[0].days.count, 10, "Hoʻonui should have 10 days (1-10)")
        XCTAssertEqual(rows[1].days.count, 6, "Poepoe should have 6 days (11-16)")
        XCTAssertEqual(rows[2].days.count, 14, "Emi should have 14 days (17-30)")
    }
    
    func testBuildGroupRowsHasOneActiveGroup() {
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        let rows = MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: testDate)
        
        let activeCount = rows.filter { $0.isActiveGroup }.count
        XCTAssertEqual(activeCount, 1, "Exactly one group should be active")
    }
    
    func testBuildGroupRowsFillStateProgression() {
        /*
         * When active phase is day 14, all days up to 14 should be filled
         */
        let testDate = dateFromString("2025-06-15")
        let monthData = MoonCalendarGenerator.buildMonthData(for: testDate)
        
        /*
         * Find a date in the month with lunar phase around 14
         */
        for moonDay in monthData.monthBuilt {
            if moonDay.phase.primary.day == 14 {
                let rows = MoonCalendarGenerator.buildGroupRows(
                    monthData: monthData,
                    activeDate: moonDay.date
                )
                
                /*
                 * All days in Hoʻonui (1-10) should be filled
                 */
                let hoonuiFilled = rows[0].days.filter { $0.isFilled }.count
                XCTAssertEqual(hoonuiFilled, 10, "All Hoʻonui days should be filled")
                
                /*
                 * Days 11-14 in Poepoe should be filled
                 */
                let poepoeFilled = rows[1].days.filter { $0.isFilled }.count
                XCTAssertEqual(poepoeFilled, 4, "Days 11-14 should be filled in Poepoe")
                
                /*
                 * No days in Emi should be filled
                 */
                let emiFilled = rows[2].days.filter { $0.isFilled }.count
                XCTAssertEqual(emiFilled, 0, "No Emi days should be filled yet")
                
                return
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testPhaseAtYearBoundary() {
        let dec31 = dateFromString("2025-12-31")
        let jan1 = dateFromString("2026-01-01")
        
        let dec31Phase = MoonCalendarGenerator.phase(for: dec31)
        let jan1Phase = MoonCalendarGenerator.phase(for: jan1)
        
        XCTAssertNotNil(dec31Phase.primary)
        XCTAssertNotNil(jan1Phase.primary)
        
        /*
         * Phases should advance by 0 or 1 across year boundary (with wrapping).
         * Same-phase is possible on rare occasions near the Hilo boundary.
         */
        let validProgression =
        jan1Phase.primary.day == dec31Phase.primary.day
        || jan1Phase.primary.day == dec31Phase.primary.day + 1
        || (dec31Phase.primary.day == 30 && jan1Phase.primary.day == 1)
        
        XCTAssertTrue(
            validProgression,
            "Phases should advance smoothly across year boundary: \(dec31Phase.primary.day) -> \(jan1Phase.primary.day)"
        )
    }
    
    func testMonthDataAtYearBoundary() {
        let dec2025 = dateFromString("2025-12-15")
        let jan2026 = dateFromString("2026-01-15")
        
        let decData = MoonCalendarGenerator.buildMonthData(for: dec2025, includeOverlap: true)
        let janData = MoonCalendarGenerator.buildMonthData(for: jan2026, includeOverlap: true)
        
        XCTAssertEqual(decData.year, 2025)
        XCTAssertEqual(janData.year, 2026)
        
        /*
         * Both months should generate valid data
         */
        XCTAssertFalse(decData.monthBuilt.isEmpty)
        XCTAssertFalse(janData.monthBuilt.isEmpty)
    }
    
    func testSameDateReturnsConsistentResults() {
        /*
         * Calling phase(for:) multiple times should return consistent results
         */
        let testDate = dateFromString("2025-08-20")
        
        let result1 = MoonCalendarGenerator.phase(for: testDate)
        let result2 = MoonCalendarGenerator.phase(for: testDate)
        let result3 = MoonCalendarGenerator.phase(for: testDate)
        
        XCTAssertEqual(result1.primary.day, result2.primary.day)
        XCTAssertEqual(result2.primary.day, result3.primary.day)
        XCTAssertEqual(result1.isTransitionDay, result2.isTransitionDay)
        XCTAssertEqual(result2.isTransitionDay, result3.isTransitionDay)
    }
    
    // MARK: - Performance Tests
    
    func testBuildMonthDataPerformance() {
        let testDate = dateFromString("2025-06-15")
        
        measure {
            for _ in 0..<100 {
                _ = MoonCalendarGenerator.buildMonthData(for: testDate, includeOverlap: true)
            }
        }
    }
    
    func testPhaseCalculationPerformance() {
        let startDate = dateFromString("2025-01-01")
        
        measure {
            for dayOffset in 0..<365 {
                let testDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
                _ = MoonCalendarGenerator.phase(for: testDate)
            }
        }
    }
}
