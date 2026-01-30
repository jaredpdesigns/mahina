import XCTest

@testable import MahinaAssets

/// Analysis tests to understand the pattern behind Hawaiian calendar transition days.
/// Reference: 2025 printed Hawaiian Moon Calendar shows these transition days:
/// - February 27
/// - March 12
/// - May 26
/// - July 22
final class TransitionDayAnalysisTests: XCTestCase {

    // Known transition days from the 2025 printed Hawaiian calendar
    let knownTransitionDays2025: [(month: Int, day: Int, phases: String)] = [
        (2, 27, "Muku/Hilo (30→1)"),  // February 27
        (3, 12, "Unknown"),  // March 12
        (5, 26, "Unknown"),  // May 26
        (7, 22, "Unknown"),  // July 22
    ]

    /// Analyze lunar data for each known transition day
    func testAnalyzeKnownTransitionDays() {
        let cal = Calendar.current

        print("\n=== ANALYSIS OF KNOWN 2025 TRANSITION DAYS ===\n")

        for (month, day, expectedPhases) in knownTransitionDays2025 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = day

            guard let date = cal.date(from: components) else {
                XCTFail("Could not create date for \(month)/\(day)/2025")
                continue
            }

            analyzeDate(date, expected: expectedPhases)
        }
    }

    /// Analyze days around each known transition to see the pattern
    func testAnalyzeDaysAroundTransitions() {
        let cal = Calendar.current

        print("\n=== DAYS AROUND KNOWN TRANSITIONS ===\n")

        for (month, day, _) in knownTransitionDays2025 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = day

            guard let centerDate = cal.date(from: components) else { continue }

            print("--- Around \(month)/\(day)/2025 ---")

            // Check 2 days before and after
            for offset in -2...2 {
                guard let date = cal.date(byAdding: .day, value: offset, to: centerDate) else {
                    continue
                }
                let dayNum = cal.component(.day, from: date)
                let marker = offset == 0 ? " <<<" : ""
                analyzeDate(date, label: "  Day \(dayNum)\(marker)")
            }
            print("")
        }
    }

    /// Check what our current algorithm flags vs what it should flag
    func testCurrentAlgorithmVsExpected() {
        let cal = Calendar.current

        print("\n=== CURRENT ALGORITHM OUTPUT FOR 2025 ===\n")

        var flaggedDays: [(month: Int, day: Int)] = []

        // Check all days in 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1

        guard var currentDate = cal.date(from: components) else { return }

        let endComponents = DateComponents(year: 2026, month: 1, day: 1)
        guard let endDate = cal.date(from: endComponents) else { return }

        while currentDate < endDate {
            let result = MoonCalendarGenerator.phase(for: currentDate)
            if result.isTransitionDay {
                let month = cal.component(.month, from: currentDate)
                let day = cal.component(.day, from: currentDate)
                flaggedDays.append((month, day))
            }
            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
        }

        print("Flagged \(flaggedDays.count) transition days in 2025:")
        for (month, day) in flaggedDays {
            let isKnown = knownTransitionDays2025.contains { $0.month == month && $0.day == day }
            let marker = isKnown ? " ✓ EXPECTED" : ""
            print("  \(month)/\(day)\(marker)")
        }

        print("\nExpected days that were MISSED:")
        for (month, day, phases) in knownTransitionDays2025 {
            let wasFound = flaggedDays.contains { $0.0 == month && $0.1 == day }
            if !wasFound {
                print("  \(month)/\(day) (\(phases)) - MISSED!")
            }
        }
    }

    /// Calculate the EXACT time when phase boundary crosses
    func testFindExactTransitionTimes() {
        let cal = Calendar.current

        print("\n=== EXACT TRANSITION TIMES FOR KNOWN DAYS ===\n")

        for (month, day, _) in knownTransitionDays2025 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = day

            guard let date = cal.date(from: components) else { continue }

            let startOfDay = cal.startOfDay(for: date)

            // Check every hour to find when phase changes
            var previousPhase = -1
            var transitionHour: Int?

            for hour in 0...23 {
                guard let time = cal.date(byAdding: .hour, value: hour, to: startOfDay) else {
                    continue
                }
                let age = MoonCalendarGenerator.lunarAge(for: time)
                let dayInCycle = (age / 29.530588) * 30.0
                var phase = Int(round(dayInCycle))
                if phase <= 0 { phase = 1 }
                if phase > 30 { phase = 1 }

                if previousPhase != -1 && phase != previousPhase {
                    transitionHour = hour
                    print(
                        "\(month)/\(day): Phase changes from \(previousPhase)→\(phase) around \(hour-1):00-\(hour):00"
                    )
                    break
                }
                previousPhase = phase
            }

            if transitionHour == nil {
                print("\(month)/\(day): No phase change detected within the day")
            }
        }
    }

    /// Analyze ALL days in each month to see the pattern
    func testFullMonthAnalysis() {
        let cal = Calendar.current

        let monthsToAnalyze = [2, 3, 5, 7]  // Feb, Mar, May, Jul

        print("\n=== FULL MONTH ANALYSIS - TRANSITION TIMES ===\n")

        for month in monthsToAnalyze {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 1

            guard var date = cal.date(from: components) else { continue }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            print("--- \(formatter.string(from: date)) 2025 ---")

            while cal.component(.month, from: date) == month {
                let dayNum = cal.component(.day, from: date)
                let startOfDay = cal.startOfDay(for: date)

                guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                    let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
                else {
                    date = cal.date(byAdding: .day, value: 1, to: date)!
                    continue
                }

                let morningAge = MoonCalendarGenerator.lunarAge(for: morning)
                let eveningAge = MoonCalendarGenerator.lunarAge(for: evening)

                var morningPhase = Int(round((morningAge / 29.530588) * 30.0))
                var eveningPhase = Int(round((eveningAge / 29.530588) * 30.0))
                if morningPhase <= 0 { morningPhase = 1 }
                if morningPhase > 30 { morningPhase = 1 }
                if eveningPhase <= 0 { eveningPhase = 1 }
                if eveningPhase > 30 { eveningPhase = 1 }

                let isKnown = knownTransitionDays2025.contains {
                    $0.month == month && $0.day == dayNum
                }
                let changes = morningPhase != eveningPhase

                if changes {
                    let marker = isKnown ? " ← MARKED IN CALENDAR" : ""
                    print(
                        "  Day \(String(format: "%2d", dayNum)): \(morningPhase)→\(eveningPhase)\(marker)"
                    )
                }

                date = cal.date(byAdding: .day, value: 1, to: date)!
            }
            print("")
        }
    }

    /// Test filtering by significant phases only
    func testSignificantPhaseTransitions() {
        let cal = Calendar.current

        // Significant phases in Hawaiian calendar:
        // 1 (Hilo) = New Moon
        // 14 (Akua) = Full Moon
        // 15 (Hoku) = After Full Moon
        // 30 (Muku) = Last phase before New Moon
        let significantPhases: Set<Int> = [1, 14, 15, 30]

        print("\n=== SIGNIFICANT PHASE TRANSITIONS IN 2025 ===\n")
        print("Showing only transitions INTO phases: 1 (Hilo), 14 (Akua), 15 (Hoku), 30 (Muku)\n")

        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1

        guard var currentDate = cal.date(from: components) else { return }

        let endComponents = DateComponents(year: 2026, month: 1, day: 1)
        guard let endDate = cal.date(from: endComponents) else { return }

        var foundDates: [(month: Int, day: Int, transition: String)] = []

        while currentDate < endDate {
            let startOfDay = cal.startOfDay(for: currentDate)

            guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
            else {
                currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
                continue
            }

            let morningAge = MoonCalendarGenerator.lunarAge(for: morning)
            let eveningAge = MoonCalendarGenerator.lunarAge(for: evening)

            var morningPhase = Int(round((morningAge / 29.530588) * 30.0))
            var eveningPhase = Int(round((eveningAge / 29.530588) * 30.0))
            if morningPhase <= 0 { morningPhase = 1 }
            if morningPhase > 30 { morningPhase = 1 }
            if eveningPhase <= 0 { eveningPhase = 1 }
            if eveningPhase > 30 { eveningPhase = 1 }

            // Check if transitioning INTO a significant phase
            if morningPhase != eveningPhase && significantPhases.contains(eveningPhase) {
                let month = cal.component(.month, from: currentDate)
                let day = cal.component(.day, from: currentDate)
                foundDates.append((month, day, "\(morningPhase)→\(eveningPhase)"))
            }

            currentDate = cal.date(byAdding: .day, value: 1, to: currentDate)!
        }

        print("Found \(foundDates.count) significant transition days:\n")
        for (month, day, transition) in foundDates {
            let isKnown = knownTransitionDays2025.contains { $0.month == month && $0.day == day }
            let marker = isKnown ? " ✓ EXPECTED" : ""
            print("  \(month)/\(day): \(transition)\(marker)")
        }

        print("\nExpected days check:")
        for (month, day, phases) in knownTransitionDays2025 {
            let wasFound = foundDates.contains { $0.0 == month && $0.1 == day }
            print("  \(month)/\(day) (\(phases)): \(wasFound ? "✓ Found" : "✗ MISSED")")
        }
    }

    /// Use actual buildMonthData to see what gets flagged
    func testActualMonthDataOutput() {
        let cal = Calendar.current

        print("\n=== ACTUAL buildMonthData OUTPUT FOR 2025 ===\n")

        for month in 1...12 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 15

            guard let date = cal.date(from: components) else { continue }

            let monthData = MoonCalendarGenerator.buildMonthData(for: date)
            let transitionDays = monthData.monthBuilt.filter {
                $0.phase.isTransitionDay && !$0.isOverlap
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: date)

            if transitionDays.isEmpty {
                print("\(monthName): No transition days")
            } else {
                let daysList = transitionDays.map { day -> String in
                    let dayNum = cal.component(.day, from: day.date)
                    let primary = day.phase.primary.day
                    let secondary = day.phase.secondary?.day ?? 0
                    let isKnown = knownTransitionDays2025.contains {
                        $0.month == month && $0.day == dayNum
                    }
                    let marker = isKnown ? " ✓" : ""
                    return "\(dayNum) (\(secondary)→\(primary))\(marker)"
                }
                print(
                    "\(monthName): \(transitionDays.count) days - \(daysList.joined(separator: ", "))"
                )
            }
        }

        print("\n--- ANALYSIS ---")
        print("We're seeing 2-4 days per month because we flag:")
        print("  - Both →14 (Akua) AND →15 (Hoku) near full moon")
        print("  - Both →30 (Muku) AND →1 (Hilo) near new moon")
        print("The printed calendar likely picks just ONE per lunar event.")
    }

    /// Test picking FIRST transition per calendar month only
    func testFirstPerCalendarMonth() {
        let cal = Calendar.current

        print("\n=== FIRST TRANSITION PER CALENDAR MONTH ===\n")
        print("Rule: Only flag the FIRST significant transition in each calendar month\n")

        let refinedPhases: Set<Int> = [1, 14, 30]
        var selectedDays: [(month: Int, day: Int, into: Int)] = []

        for month in 1...12 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 1

            guard var date = cal.date(from: components) else { continue }

            var foundFirst = false

            while cal.component(.month, from: date) == month && !foundFirst {
                let startOfDay = cal.startOfDay(for: date)

                guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                    let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
                else {
                    date = cal.date(byAdding: .day, value: 1, to: date)!
                    continue
                }

                let mAge = MoonCalendarGenerator.lunarAge(for: morning)
                let eAge = MoonCalendarGenerator.lunarAge(for: evening)

                var mPhase = Int(round((mAge / 29.530588) * 30.0))
                var ePhase = Int(round((eAge / 29.530588) * 30.0))
                if mPhase <= 0 { mPhase = 1 }
                if mPhase > 30 { mPhase = 1 }
                if ePhase <= 0 { ePhase = 1 }
                if ePhase > 30 { ePhase = 1 }

                if mPhase != ePhase && refinedPhases.contains(ePhase) {
                    let dayNum = cal.component(.day, from: date)
                    selectedDays.append((month, dayNum, ePhase))
                    foundFirst = true
                }

                date = cal.date(byAdding: .day, value: 1, to: date)!
            }
        }

        print("Selected (first per month):")
        for (month, day, into) in selectedDays {
            let isKnown = knownTransitionDays2025.contains { $0.month == month && $0.day == day }
            let phaseName = into == 1 ? "Hilo" : (into == 14 ? "Akua" : "Muku")
            let marker = isKnown ? " ✓ EXPECTED" : ""
            print("  \(month)/\(day) (→\(into) \(phaseName))\(marker)")
        }

        print("\nTotal: \(selectedDays.count) days")

        print("\nExpected days check:")
        for (month, day, phases) in knownTransitionDays2025 {
            let wasFound = selectedDays.contains { $0.month == month && $0.day == day }
            print("  \(month)/\(day) (\(phases)): \(wasFound ? "✓ Found" : "✗ MISSED")")
        }
    }

    /// Test picking only ONE transition per synodic month
    func testOnePerSynodicMonth() {
        let cal = Calendar.current

        print("\n=== ONE TRANSITION PER SYNODIC MONTH ===\n")
        print("Rule: For each new moon cycle, pick only ONE transition day\n")
        print("Priority: →14 (Akua/Full) if available, else →30/→1 (New Moon)\n")

        let refinedPhases: Set<Int> = [1, 14, 30]
        var allTransitions: [(date: Date, month: Int, day: Int, into: Int)] = []

        // Gather all transitions
        for month in 1...12 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 1

            guard var date = cal.date(from: components) else { continue }

            while cal.component(.month, from: date) == month {
                let startOfDay = cal.startOfDay(for: date)

                guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                    let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
                else {
                    date = cal.date(byAdding: .day, value: 1, to: date)!
                    continue
                }

                let mAge = MoonCalendarGenerator.lunarAge(for: morning)
                let eAge = MoonCalendarGenerator.lunarAge(for: evening)

                var mPhase = Int(round((mAge / 29.530588) * 30.0))
                var ePhase = Int(round((eAge / 29.530588) * 30.0))
                if mPhase <= 0 { mPhase = 1 }
                if mPhase > 30 { mPhase = 1 }
                if ePhase <= 0 { ePhase = 1 }
                if ePhase > 30 { ePhase = 1 }

                if mPhase != ePhase && refinedPhases.contains(ePhase) {
                    let dayNum = cal.component(.day, from: date)
                    allTransitions.append((date, month, dayNum, ePhase))
                }

                date = cal.date(byAdding: .day, value: 1, to: date)!
            }
        }

        // Group by synodic month (roughly every ~29.5 days from a reference new moon)
        // Use Feb 27 as reference (it's a →1 transition)
        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 27
        let referenceNewMoon = cal.date(from: components)!

        print("Grouping transitions by synodic month (ref: Feb 27, 2025):\n")

        // Calculate which synodic month each transition belongs to
        var synodicGroups: [Int: [(month: Int, day: Int, into: Int)]] = [:]

        for t in allTransitions {
            let daysSinceRef =
                cal.dateComponents([.day], from: referenceNewMoon, to: t.date).day ?? 0
            let synodicMonth = Int(round(Double(daysSinceRef) / 29.53))

            if synodicGroups[synodicMonth] == nil {
                synodicGroups[synodicMonth] = []
            }
            synodicGroups[synodicMonth]?.append((t.month, t.day, t.into))
        }

        var selectedDays: [(month: Int, day: Int, into: Int)] = []

        for synodicMonth in synodicGroups.keys.sorted() {
            let group = synodicGroups[synodicMonth]!

            // Pick ONE: prefer →14 (full moon), then →1 (new moon), then →30 (dark moon)
            let selected: (month: Int, day: Int, into: Int)
            if let akua = group.first(where: { $0.into == 14 }) {
                selected = akua
            } else if let hilo = group.first(where: { $0.into == 1 }) {
                selected = hilo
            } else {
                selected = group.first!
            }

            selectedDays.append(selected)

            let groupStr = group.map { "\($0.month)/\($0.day) →\($0.into)" }.joined(separator: ", ")
            let isKnown = knownTransitionDays2025.contains {
                $0.month == selected.month && $0.day == selected.day
            }
            let marker = isKnown ? " ✓" : ""
            print(
                "  Synodic \(synodicMonth): [\(groupStr)] → picked \(selected.month)/\(selected.day)\(marker)"
            )
        }

        print("\nTotal selected: \(selectedDays.count) days")

        print("\nExpected days check:")
        for (month, day, phases) in knownTransitionDays2025 {
            let wasFound = selectedDays.contains { $0.month == month && $0.day == day }
            print("  \(month)/\(day) (\(phases)): \(wasFound ? "✓ Found" : "✗ MISSED")")
        }
    }

    /// Test with refined significant phases (no Hoku)
    func testRefinedSignificantPhases() {
        let cal = Calendar.current

        // Refined: Remove Hoku (15) - only flag Akua (14) for full moon
        let refinedSignificantPhases: Set<Int> = [1, 14, 30]

        print("\n=== REFINED SIGNIFICANT PHASES (no Hoku) ===\n")
        print("Only flagging transitions INTO: 1 (Hilo), 14 (Akua), 30 (Muku)\n")

        var transitionsByMonth: [Int: [(day: Int, into: Int)]] = [:]

        for month in 1...12 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 1

            guard var date = cal.date(from: components) else { continue }

            transitionsByMonth[month] = []

            while cal.component(.month, from: date) == month {
                let startOfDay = cal.startOfDay(for: date)

                guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                    let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
                else {
                    date = cal.date(byAdding: .day, value: 1, to: date)!
                    continue
                }

                let mAge = MoonCalendarGenerator.lunarAge(for: morning)
                let eAge = MoonCalendarGenerator.lunarAge(for: evening)

                var mPhase = Int(round((mAge / 29.530588) * 30.0))
                var ePhase = Int(round((eAge / 29.530588) * 30.0))
                if mPhase <= 0 { mPhase = 1 }
                if mPhase > 30 { mPhase = 1 }
                if ePhase <= 0 { ePhase = 1 }
                if ePhase > 30 { ePhase = 1 }

                if mPhase != ePhase && refinedSignificantPhases.contains(ePhase) {
                    let dayNum = cal.component(.day, from: date)
                    transitionsByMonth[month]?.append((dayNum, ePhase))
                }

                date = cal.date(byAdding: .day, value: 1, to: date)!
            }
        }

        var totalDays = 0
        for month in 1...12 {
            let transitions = transitionsByMonth[month] ?? []
            totalDays += transitions.count

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 1
            let date = cal.date(from: components)!
            let monthName = formatter.string(from: date)

            if transitions.isEmpty {
                print("\(monthName): No transition days")
            } else {
                let daysList = transitions.map { t -> String in
                    let isKnown = knownTransitionDays2025.contains {
                        $0.month == month && $0.day == t.day
                    }
                    let phaseName = t.into == 1 ? "Hilo" : (t.into == 14 ? "Akua" : "Muku")
                    let marker = isKnown ? " ✓" : ""
                    return "\(t.day) (→\(t.into) \(phaseName))\(marker)"
                }
                print(
                    "\(monthName): \(transitions.count) days - \(daysList.joined(separator: ", "))")
            }
        }

        print("\nTotal: \(totalDays) transition days in 2025")

        print("\nExpected days check:")
        for (month, day, phases) in knownTransitionDays2025 {
            let wasFound = transitionsByMonth[month]?.contains { $0.day == day } ?? false
            print("  \(month)/\(day) (\(phases)): \(wasFound ? "✓ Found" : "✗ MISSED")")
        }
    }

    /// Analyze the clustering of transition days
    func testTransitionDayClustering() {
        let cal = Calendar.current

        print("\n=== TRANSITION DAY CLUSTERING ANALYSIS ===\n")

        var allTransitions: [(month: Int, day: Int, into: Int)] = []

        for month in 1...12 {
            var components = DateComponents()
            components.year = 2025
            components.month = month
            components.day = 15

            guard let date = cal.date(from: components) else { continue }

            let monthData = MoonCalendarGenerator.buildMonthData(for: date)

            for moonDay in monthData.monthBuilt
            where moonDay.phase.isTransitionDay && !moonDay.isOverlap {
                let dayNum = cal.component(.day, from: moonDay.date)
                let intoPhase = moonDay.phase.primary.day
                allTransitions.append((month, dayNum, intoPhase))
            }
        }

        print("All 2025 transitions grouped by lunar event:\n")

        // Group by which lunar event (new moon vs full moon)
        var newMoonTransitions: [(month: Int, day: Int, into: Int)] = []
        var fullMoonTransitions: [(month: Int, day: Int, into: Int)] = []

        for t in allTransitions {
            if t.into == 1 || t.into == 30 {
                newMoonTransitions.append(t)
            } else if t.into == 14 || t.into == 15 {
                fullMoonTransitions.append(t)
            }
        }

        print("NEW MOON events (→30 Muku or →1 Hilo):")
        for t in newMoonTransitions {
            let isKnown = knownTransitionDays2025.contains {
                $0.month == t.month && $0.day == t.day
            }
            let marker = isKnown ? " ✓ EXPECTED" : ""
            print("  \(t.month)/\(t.day): →\(t.into)\(marker)")
        }

        print("\nFULL MOON events (→14 Akua or →15 Hoku):")
        for t in fullMoonTransitions {
            let isKnown = knownTransitionDays2025.contains {
                $0.month == t.month && $0.day == t.day
            }
            let marker = isKnown ? " ✓ EXPECTED" : ""
            print("  \(t.month)/\(t.day): →\(t.into)\(marker)")
        }

        print("\n--- HYPOTHESIS ---")
        print("If printed calendar picks ONE day per event, they might use:")
        print("  • For new moon: prefer →1 (Hilo) over →30 (Muku)")
        print("  • For full moon: prefer →14 (Akua) over →15 (Hoku)")
    }

    /// Analyze phase progression around transition days
    func testPhaseProgressionAroundTransition() {
        let cal = Calendar.current

        print("\n=== PHASE PROGRESSION AROUND TRANSITION DAYS ===\n")
        print("Question: On transition days, should primary be the ENDING or BEGINNING phase?\n")

        // Test Feb 25-28, 2025 (known transition)
        print("--- February 2025 (around Feb 27 transition) ---")
        for day in 25...28 {
            var components = DateComponents()
            components.year = 2025
            components.month = 2
            components.day = day

            guard let date = cal.date(from: components) else { continue }

            let result = MoonCalendarGenerator.phase(for: date)
            let primary = result.primary
            let secondary = result.secondary

            let isTransition = result.isTransitionDay
            let secondaryStr =
                secondary != nil ? " → \(secondary!.day) (\(secondary!.name)) begins" : ""
            let marker = isTransition ? " ← TRANSITION" : ""

            print("  Feb \(day): Phase \(primary.day) (\(primary.name))\(secondaryStr)\(marker)")
        }

        print("")

        // Test Jan 17-20, 2026
        print("--- January 2026 (around expected transition) ---")
        for day in 17...20 {
            var components = DateComponents()
            components.year = 2026
            components.month = 1
            components.day = day

            guard let date = cal.date(from: components) else { continue }

            let result = MoonCalendarGenerator.phase(for: date)
            let primary = result.primary
            let secondary = result.secondary

            let isTransition = result.isTransitionDay
            let secondaryStr =
                secondary != nil ? " (secondary: \(secondary!.day) \(secondary!.name))" : ""
            let marker = isTransition ? " ← TRANSITION" : ""

            print("  Jan \(day): Phase \(primary.day) (\(primary.name))\(secondaryStr)\(marker)")
        }

        // Also check the 6am and 6pm phases directly
        print("\n--- Detailed 6am/6pm analysis ---")
        for day in 17...20 {
            var components = DateComponents()
            components.year = 2026
            components.month = 1
            components.day = day

            guard let date = cal.date(from: components) else { continue }
            let startOfDay = cal.startOfDay(for: date)

            guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
            else { continue }

            let mAge = MoonCalendarGenerator.lunarAge(for: morning)
            let eAge = MoonCalendarGenerator.lunarAge(for: evening)

            var mPhase = Int(round((mAge / 29.530588) * 30.0))
            var ePhase = Int(round((eAge / 29.530588) * 30.0))
            if mPhase <= 0 { mPhase = 1 }
            if mPhase > 30 { mPhase = 1 }
            if ePhase <= 0 { ePhase = 1 }
            if ePhase > 30 { ePhase = 1 }

            let changes = mPhase != ePhase ? "CHANGES" : "same"
            print("  Jan \(day): 6am=\(mPhase), 6pm=\(ePhase) (\(changes))")
        }

        print("\n--- Analysis ---")
        print("If primary = evening phase:")
        print("  Transition day shows the NEW phase as primary")
        print("  Next day also shows the NEW phase")
        print("  → Two consecutive days with same primary phase")
        print("")
        print("If primary = morning phase:")
        print("  Transition day shows the OLD phase as primary")
        print("  Next day shows the NEW phase")
        print("  → Clean day-by-day progression")
    }

    /// Deep dive into July to understand the July 22 vs July 24 question
    func testJulyDeepDive() {
        let cal = Calendar.current

        print("\n=== JULY 2025 DEEP DIVE ===\n")
        print("Full analysis of July 20-26:\n")

        for day in 20...26 {
            var components = DateComponents()
            components.year = 2025
            components.month = 7
            components.day = day

            guard let date = cal.date(from: components) else { continue }

            let startOfDay = cal.startOfDay(for: date)

            var phases: [String] = []
            for (name, hours) in [("midnight", 0), ("6am", 6), ("noon", 12), ("6pm", 18)] {
                guard let time = cal.date(byAdding: .hour, value: hours, to: startOfDay) else {
                    continue
                }
                let age = MoonCalendarGenerator.lunarAge(for: time)
                var phase = Int(round((age / 29.530588) * 30.0))
                if phase <= 0 { phase = 1 }
                if phase > 30 { phase = 1 }
                phases.append("\(name):\(phase)")
            }

            guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
                let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
            else { continue }

            let mAge = MoonCalendarGenerator.lunarAge(for: morning)
            let eAge = MoonCalendarGenerator.lunarAge(for: evening)

            var mPhase = Int(round((mAge / 29.530588) * 30.0))
            var ePhase = Int(round((eAge / 29.530588) * 30.0))
            if mPhase <= 0 { mPhase = 1 }
            if mPhase > 30 { mPhase = 1 }
            if ePhase <= 0 { ePhase = 1 }
            if ePhase > 30 { ePhase = 1 }

            let changes = mPhase != ePhase ? "CHANGES \(mPhase)→\(ePhase)" : "same (\(mPhase))"
            let isSignificant = [1, 14, 15, 30].contains(ePhase) && mPhase != ePhase
            let marker = isSignificant ? " ★ SIGNIFICANT" : ""
            let isMarked = day == 22 ? " ← USER SAYS MARKED" : ""

            print("Jul \(day): \(changes)\(marker)\(isMarked)")
            print("        \(phases.joined(separator: ", "))")
        }

        print("\n⚠️  If printed calendar shows Jul 22 as transition day,")
        print("    but our calculation shows Jul 24 as the 29→30 transition,")
        print("    they may be using a different lunar calculation or timezone.")
    }

    // MARK: - Helper Methods

    private func analyzeDate(_ date: Date, expected: String = "", label: String = "") {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)

        let startOfDay = cal.startOfDay(for: date)

        // Calculate at various times throughout the day
        let times: [(String, Int)] = [
            ("midnight", 0),
            ("6am", 6),
            ("noon", 12),
            ("6pm", 18),
            ("11pm", 23),
        ]

        let header = label.isEmpty ? "\(month)/\(day)/2025 \(expected)" : label
        print(header)

        for (timeName, hours) in times {
            guard let time = cal.date(byAdding: .hour, value: hours, to: startOfDay) else {
                continue
            }

            let age = MoonCalendarGenerator.lunarAge(for: time)
            let dayInCycle = (age / 29.530588) * 30.0
            var phase = Int(round(dayInCycle))
            if phase <= 0 { phase = 1 }
            if phase > 30 { phase = 1 }

            let fractional = dayInCycle - Double(Int(dayInCycle))

            print(
                "    \(timeName.padding(toLength: 10, withPad: " ", startingAt: 0)): age=\(String(format: "%.2f", age))d, dayInCycle=\(String(format: "%.3f", dayInCycle)), frac=\(String(format: "%.3f", fractional)), phase=\(phase)"
            )
        }

        // Check if phases change during the day
        guard let morning = cal.date(byAdding: .hour, value: 6, to: startOfDay),
            let evening = cal.date(byAdding: .hour, value: 18, to: startOfDay)
        else { return }

        let morningAge = MoonCalendarGenerator.lunarAge(for: morning)
        let eveningAge = MoonCalendarGenerator.lunarAge(for: evening)

        let morningCycle = (morningAge / 29.530588) * 30.0
        let eveningCycle = (eveningAge / 29.530588) * 30.0

        var morningPhase = Int(round(morningCycle))
        var eveningPhase = Int(round(eveningCycle))
        if morningPhase <= 0 { morningPhase = 1 }
        if morningPhase > 30 { morningPhase = 1 }
        if eveningPhase <= 0 { eveningPhase = 1 }
        if eveningPhase > 30 { eveningPhase = 1 }

        let phaseChanges = morningPhase != eveningPhase
        print(
            "    Phase 6am→6pm: \(morningPhase)→\(eveningPhase) \(phaseChanges ? "CHANGES" : "same")"
        )
        print("")
    }
}
