import XCTest
@testable import MahinaAssets

/// Tests for LunarPhases static data integrity and lookup functions.
///
/// Ensures all 30 Hawaiian lunar phases have complete, valid data including
/// names, descriptions, and traditional guidance for planting and fishing.
final class LunarPhasesTests: XCTestCase {

    // MARK: - Data Completeness Tests

    func testAllThirtyPhasesExist() {
        XCTAssertEqual(LunarPhases.phases.count, 30, "Should have exactly 30 lunar phases")
    }

    func testAllDaysHaveUniqueNumbers() {
        let dayNumbers = LunarPhases.phases.map { $0.day }
        let uniqueDays = Set(dayNumbers)

        XCTAssertEqual(uniqueDays.count, 30, "All 30 days should be unique")

        for day in 1...30 {
            XCTAssertTrue(dayNumbers.contains(day), "Day \(day) should exist in phases")
        }
    }

    func testAllPhasesHaveNames() {
        for phase in LunarPhases.phases {
            XCTAssertFalse(phase.name.isEmpty,
                          "Phase for day \(phase.day) should have a name")
        }
    }

    func testAllPhasesHaveDescriptions() {
        for phase in LunarPhases.phases {
            XCTAssertFalse(phase.description.isEmpty,
                          "Phase for day \(phase.day) should have a description")
        }
    }

    func testAllPhasesHavePlantingGuidance() {
        for phase in LunarPhases.phases {
            XCTAssertFalse(phase.planting.isEmpty,
                          "Phase for day \(phase.day) should have planting guidance")
        }
    }

    func testAllPhasesHaveFishingGuidance() {
        for phase in LunarPhases.phases {
            XCTAssertFalse(phase.fishing.isEmpty,
                          "Phase for day \(phase.day) should have fishing guidance")
        }
    }

    // MARK: - Phase Lookup Tests

    func testPhaseForValidDay() {
        for day in 1...30 {
            let phase = LunarPhases.phase(for: day)
            XCTAssertNotNil(phase, "Should find phase for day \(day)")
            XCTAssertEqual(phase?.day, day, "Returned phase day should match requested day")
        }
    }

    func testPhaseForInvalidDay() {
        let phaseForZero = LunarPhases.phase(for: 0)
        XCTAssertNil(phaseForZero, "No phase should exist for day 0")

        let phaseForNegative = LunarPhases.phase(for: -1)
        XCTAssertNil(phaseForNegative, "No phase should exist for negative days")

        let phaseFor31 = LunarPhases.phase(for: 31)
        XCTAssertNil(phaseFor31, "No phase should exist for day 31")
    }

    // MARK: - Key Phase Name Verification

    func testHiloPhase() {
        let hilo = LunarPhases.phase(for: 1)
        XCTAssertEqual(hilo?.name, "Hilo", "Day 1 should be Hilo")
        XCTAssertTrue(hilo?.description.lowercased().contains("new") ?? false,
                     "Hilo description should mention new moon")
    }

    func testHoakaPhase() {
        let hoaka = LunarPhases.phase(for: 2)
        XCTAssertEqual(hoaka?.name, "Hoaka", "Day 2 should be Hoaka")
    }

    func testKuPhases() {
        /*
         * Days 3-6 are the Kū phases
         */
        let kuPhases = [
            (3, "Kūkahi"),
            (4, "Kūlua"),
            (5, "Kūkolu"),
            (6, "Kūpau")
        ]

        for (day, expectedName) in kuPhases {
            let phase = LunarPhases.phase(for: day)
            XCTAssertEqual(phase?.name, expectedName, "Day \(day) should be \(expectedName)")
        }
    }

    func testOlePhases() {
        /*
         * Days 7-10 are the first ʻOle phases
         */
        let olePhases = [
            (7, "ʻOlekūkahi"),
            (8, "ʻOlekūlua"),
            (9, "ʻOlekūkolu"),
            (10, "ʻOlepau")
        ]

        for (day, expectedName) in olePhases {
            let phase = LunarPhases.phase(for: day)
            XCTAssertEqual(phase?.name, expectedName, "Day \(day) should be \(expectedName)")
        }
    }

    func testFullMoonPhases() {
        /*
         * Days 13-16 are the full moon phases
         */
        let fullMoonPhases = [
            (13, "Hua"),
            (14, "Akua"),
            (15, "Hoku"),
            (16, "Māhealani")
        ]

        for (day, expectedName) in fullMoonPhases {
            let phase = LunarPhases.phase(for: day)
            XCTAssertEqual(phase?.name, expectedName, "Day \(day) should be \(expectedName)")
        }
    }

    func testMukuPhase() {
        let muku = LunarPhases.phase(for: 30)
        XCTAssertEqual(muku?.name, "Muku", "Day 30 should be Muku")
        XCTAssertTrue(muku?.description.lowercased().contains("dark") ?? false,
                     "Muku description should mention dark moon")
    }

    // MARK: - Guidance Quality Tests

    func testPlantingGuidanceVariety() {
        /*
         * Planting guidance should vary across phases
         */
        let allPlanting = LunarPhases.phases.map { $0.planting }
        let uniquePlanting = Set(allPlanting)

        /*
         * Allow some overlap (similar guidance for similar phases)
         * but expect reasonable variety
         */
        XCTAssertGreaterThan(uniquePlanting.count, 10,
                            "Should have variety in planting guidance")
    }

    func testFishingGuidanceVariety() {
        /*
         * Fishing guidance should vary across phases
         */
        let allFishing = LunarPhases.phases.map { $0.fishing }
        let uniqueFishing = Set(allFishing)

        XCTAssertGreaterThan(uniqueFishing.count, 10,
                            "Should have variety in fishing guidance")
    }

    func testOlePhasesDiscouragePlanting() {
        /*
         * ʻOle phases (7-10, 21-23) are traditionally unproductive
         */
        let oleDays = [7, 8, 9, 10, 21, 22, 23]

        for day in oleDays {
            let phase = LunarPhases.phase(for: day)
            let plantingLower = phase?.planting.lowercased() ?? ""

            let isDiscouraging = plantingLower.contains("avoid") ||
                                plantingLower.contains("little") ||
                                plantingLower.contains("discourage") ||
                                plantingLower.contains("maintenance") ||
                                plantingLower.contains("weeding") ||
                                plantingLower.contains("rather than")

            XCTAssertTrue(isDiscouraging,
                         "ʻOle phase \(day) should discourage planting: '\(phase?.planting ?? "")'")
        }
    }

    func testFullMoonPhasesGoodForPlanting() {
        /*
         * Full moon phases (13-16) are traditionally good for planting
         */
        let fullMoonDays = [13, 14, 15, 16]

        for day in fullMoonDays {
            let phase = LunarPhases.phase(for: day)
            let plantingLower = phase?.planting.lowercased() ?? ""

            let isPositive = plantingLower.contains("good") ||
                            plantingLower.contains("best") ||
                            plantingLower.contains("favorable") ||
                            plantingLower.contains("very good")

            XCTAssertTrue(isPositive,
                         "Full moon phase \(day) should be good for planting: '\(phase?.planting ?? "")'")
        }
    }

    // MARK: - Data Order Tests

    func testPhasesAreInOrder() {
        /*
         * Phases should be stored in day order
         */
        for (index, phase) in LunarPhases.phases.enumerated() {
            XCTAssertEqual(phase.day, index + 1,
                          "Phase at index \(index) should be day \(index + 1), got day \(phase.day)")
        }
    }
}
