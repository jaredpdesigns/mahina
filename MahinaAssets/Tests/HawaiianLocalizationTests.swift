import XCTest

@testable import MahinaAssets

/// Tests for Hawaiian language localization data and helper functions.
///
/// Verifies completeness of Hawaiian weekday and month translations,
/// and ensures lookup functions return correct values for any date.
final class HawaiianLocalizationTests: XCTestCase {

    // MARK: - Test Fixtures

    private let calendar = Calendar.current

    // MARK: - Weekday Data Completeness Tests

    func testAllSevenWeekdaysExist() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays.count, 7,
            "Should have exactly 7 weekday translations")
    }

    func testWeekdaysHaveAllIndexes() {
        for dayIndex in 1...7 {
            XCTAssertNotNil(
                HawaiianLocalization.weekdays[dayIndex],
                "Weekday index \(dayIndex) should have a translation")
        }
    }

    func testWeekdayNamesNotEmpty() {
        for (index, name) in HawaiianLocalization.weekdays {
            XCTAssertFalse(
                name.isEmpty,
                "Weekday \(index) should have a non-empty name")
        }
    }

    func testWeekdayNamesAreUnique() {
        let names = Array(HawaiianLocalization.weekdays.values)
        let uniqueNames = Set(names)

        XCTAssertEqual(
            names.count, uniqueNames.count,
            "All weekday names should be unique")
    }

    // MARK: - Weekday Name Verification

    func testSundayIsLapule() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[1], "Lāpule",
            "Sunday (index 1) should be Lāpule")
    }

    func testMondayIsPokahi() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[2], "Pōʻakahi",
            "Monday (index 2) should be Pōʻakahi")
    }

    func testTuesdayIsPolua() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[3], "Pōʻalua",
            "Tuesday (index 3) should be Pōʻalua")
    }

    func testWednesdayIsPokolu() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[4], "Pōʻakolu",
            "Wednesday (index 4) should be Pōʻakolu")
    }

    func testThursdayIsPoha() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[5], "Pōʻahā",
            "Thursday (index 5) should be Pōʻahā")
    }

    func testFridayIsPolima() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[6], "Pōʻalima",
            "Friday (index 6) should be Pōʻalima")
    }

    func testSaturdayIsPoaono() {
        XCTAssertEqual(
            HawaiianLocalization.weekdays[7], "Pōʻaono",
            "Saturday (index 7) should be Pōʻaono")
    }

    // MARK: - Month Data Completeness Tests

    func testAllTwelveMonthsExist() {
        XCTAssertEqual(
            HawaiianLocalization.months.count, 12,
            "Should have exactly 12 month translations")
    }

    func testMonthsHaveAllIndexes() {
        for monthIndex in 1...12 {
            XCTAssertNotNil(
                HawaiianLocalization.months[monthIndex],
                "Month index \(monthIndex) should have a translation")
        }
    }

    func testMonthNamesNotEmpty() {
        for (index, name) in HawaiianLocalization.months {
            XCTAssertFalse(
                name.isEmpty,
                "Month \(index) should have a non-empty name")
        }
    }

    func testMonthNamesAreUnique() {
        let names = Array(HawaiianLocalization.months.values)
        let uniqueNames = Set(names)

        XCTAssertEqual(
            names.count, uniqueNames.count,
            "All month names should be unique")
    }

    // MARK: - Month Name Verification

    func testJanuaryIsIanuali() {
        XCTAssertEqual(
            HawaiianLocalization.months[1], "Ianuali",
            "January should be Ianuali")
    }

    func testFebruaryIsPepeluali() {
        XCTAssertEqual(
            HawaiianLocalization.months[2], "Pepeluali",
            "February should be Pepeluali")
    }

    func testMarchIsMalaki() {
        XCTAssertEqual(
            HawaiianLocalization.months[3], "Malaki",
            "March should be Malaki")
    }

    func testAprilIsApelila() {
        XCTAssertEqual(
            HawaiianLocalization.months[4], "ʻApelila",
            "April should be ʻApelila")
    }

    func testMayIsMei() {
        XCTAssertEqual(
            HawaiianLocalization.months[5], "Mei",
            "May should be Mei")
    }

    func testJuneIsIune() {
        XCTAssertEqual(
            HawaiianLocalization.months[6], "Iune",
            "June should be Iune")
    }

    func testJulyIsIulai() {
        XCTAssertEqual(
            HawaiianLocalization.months[7], "Iulai",
            "July should be Iulai")
    }

    func testAugustIsAukake() {
        XCTAssertEqual(
            HawaiianLocalization.months[8], "ʻAukake",
            "August should be ʻAukake")
    }

    func testSeptemberIsKepakemapa() {
        XCTAssertEqual(
            HawaiianLocalization.months[9], "Kepakemapa",
            "September should be Kepakemapa")
    }

    func testOctoberIsOkakopa() {
        XCTAssertEqual(
            HawaiianLocalization.months[10], "ʻOkakopa",
            "October should be ʻOkakopa")
    }

    func testNovemberIsNowemapa() {
        XCTAssertEqual(
            HawaiianLocalization.months[11], "Nowemapa",
            "November should be Nowemapa")
    }

    func testDecemberIsKekemapa() {
        XCTAssertEqual(
            HawaiianLocalization.months[12], "Kekemapa",
            "December should be Kekemapa")
    }

    // MARK: - Helper Function Tests

    func testWeekdayForDateReturnsSunday() {
        /*
         * June 1, 2025 is a Sunday
         */
        let sunday = dateFromString("2025-06-01")
        let weekday = HawaiianLocalization.weekday(for: sunday)

        XCTAssertEqual(weekday, "Lāpule", "June 1, 2025 (Sunday) should be Lāpule")
    }

    func testWeekdayForDateReturnsMonday() {
        /*
         * June 2, 2025 is a Monday
         */
        let monday = dateFromString("2025-06-02")
        let weekday = HawaiianLocalization.weekday(for: monday)

        XCTAssertEqual(weekday, "Pōʻakahi", "June 2, 2025 (Monday) should be Pōʻakahi")
    }

    func testWeekdayForDateCycleThroughWeek() {
        /*
         * Test a full week starting from Sunday June 1, 2025
         */
        let expectedWeekdays = [
            "Lāpule",  // Sunday
            "Pōʻakahi",  // Monday
            "Pōʻalua",  // Tuesday
            "Pōʻakolu",  // Wednesday
            "Pōʻahā",  // Thursday
            "Pōʻalima",  // Friday
            "Pōʻaono",  // Saturday
        ]

        for (offset, expected) in expectedWeekdays.enumerated() {
            let testDate = calendar.date(
                byAdding: .day, value: offset, to: dateFromString("2025-06-01"))!
            let weekday = HawaiianLocalization.weekday(for: testDate)

            XCTAssertEqual(
                weekday, expected,
                "Day \(offset) of week should be \(expected)")
        }
    }

    func testMonthForDateReturnsJanuary() {
        let january = dateFromString("2025-01-15")
        let month = HawaiianLocalization.month(for: january)

        XCTAssertEqual(month, "Ianuali", "January should be Ianuali")
    }

    func testMonthForDateReturnsDecember() {
        let december = dateFromString("2025-12-25")
        let month = HawaiianLocalization.month(for: december)

        XCTAssertEqual(month, "Kekemapa", "December should be Kekemapa")
    }

    func testMonthForDateCycleThroughYear() {
        /*
         * Test all 12 months
         */
        let expectedMonths = [
            "Ianuali",  // January
            "Pepeluali",  // February
            "Malaki",  // March
            "ʻApelila",  // April
            "Mei",  // May
            "Iune",  // June
            "Iulai",  // July
            "ʻAukake",  // August
            "Kepakemapa",  // September
            "ʻOkakopa",  // October
            "Nowemapa",  // November
            "Kekemapa",  // December
        ]

        for (index, expected) in expectedMonths.enumerated() {
            let testDate = dateFromString(String(format: "2025-%02d-15", index + 1))
            let month = HawaiianLocalization.month(for: testDate)

            XCTAssertEqual(
                month, expected,
                "Month \(index + 1) should be \(expected)")
        }
    }

    // MARK: - Edge Case Tests

    func testWeekdayForDateAtYearBoundary() {
        let newYearsEve = dateFromString("2025-12-31")
        let newYearsDay = dateFromString("2026-01-01")

        let eveWeekday = HawaiianLocalization.weekday(for: newYearsEve)
        let dayWeekday = HawaiianLocalization.weekday(for: newYearsDay)

        XCTAssertNotNil(eveWeekday, "Should have weekday for Dec 31")
        XCTAssertNotNil(dayWeekday, "Should have weekday for Jan 1")
    }

    func testMonthForDateAtYearBoundary() {
        let dec31 = dateFromString("2025-12-31")
        let jan1 = dateFromString("2026-01-01")

        let decMonth = HawaiianLocalization.month(for: dec31)
        let janMonth = HawaiianLocalization.month(for: jan1)

        XCTAssertEqual(decMonth, "Kekemapa", "December 31 should be Kekemapa")
        XCTAssertEqual(janMonth, "Ianuali", "January 1 should be Ianuali")
    }

    func testMonthForLeapYearFebruary() {
        let feb2024 = dateFromString("2024-02-29")  // Leap year
        let month = HawaiianLocalization.month(for: feb2024)

        XCTAssertEqual(month, "Pepeluali", "February 29 should still be Pepeluali")
    }

    // MARK: - Hawaiian Language Character Tests

    func testWeekdaysContainOkina() {
        /*
         * ʻ (okina) should appear in some weekday names
         */
        let namesWithOkina = HawaiianLocalization.weekdays.values.filter { $0.contains("ʻ") }

        XCTAssertGreaterThan(
            namesWithOkina.count, 0,
            "Some weekday names should contain ʻokina")
    }

    func testMonthsContainOkina() {
        /*
         * ʻ (okina) should appear in some month names
         */
        let namesWithOkina = HawaiianLocalization.months.values.filter { $0.contains("ʻ") }

        XCTAssertGreaterThan(
            namesWithOkina.count, 0,
            "Some month names should contain ʻokina")
    }

    func testWeekdaysContainKahako() {
        /*
         * ā, ē, ī, ō, ū (kahakō/macron) should appear in some names
         */
        let kahako = CharacterSet(charactersIn: "āēīōūĀĒĪŌŪ")
        let namesWithKahako = HawaiianLocalization.weekdays.values.filter { name in
            name.unicodeScalars.contains { kahako.contains($0) }
        }

        XCTAssertGreaterThan(
            namesWithKahako.count, 0,
            "Some weekday names should contain kahakō")
    }
}
