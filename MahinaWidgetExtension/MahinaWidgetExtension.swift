import MahinaAssets
import SwiftUI
import WidgetKit

/// Timeline entry for the Mahina widget containing moon phase information for a specific date
struct DayEntry: TimelineEntry {
    let date: Date
    let phase: PhaseResult?
}

/// Timeline entry for the Upcoming Phases widget containing multiple upcoming phase results
struct UpcomingPhasesEntry: TimelineEntry {
    let date: Date
    let phases: [DatePhaseResult]
}

/// A date paired with its phase result for upcoming phases display
struct DatePhaseResult: Identifiable {
    let id = UUID()
    let date: Date
    let phase: PhaseResult
}

/// Timeline provider that supplies moon phase data to the iOS home screen widget.
///
/// Refreshes every 6 hours to keep the displayed lunar information current throughout the day.
/// Provides placeholder content and handles both snapshot and timeline generation for the widget system.
struct Provider: TimelineProvider {
    
    // MARK: - TimelineProvider Implementation
    
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), phase: previewPhase())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        let phaseResult = MoonCalendarGenerator.phase(for: Date())
        completion(DayEntry(date: Date(), phase: phaseResult))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        /* Create entry for today */
        let todayPhase = MoonCalendarGenerator.phase(for: now)
        let todayEntry = DayEntry(date: now, phase: todayPhase)
        
        /* Refresh at start of next day when phase changes */
        let startOfNextDay = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now) ?? now
        )
        
        let timeline = Timeline(entries: [todayEntry], policy: .after(startOfNextDay))
        completion(timeline)
    }
    
    // MARK: - Helper Methods
    
    /// Fallback phase for previews if no data available
    private func previewPhase() -> PhaseResult? {
        MoonCalendarGenerator.phase(for: Date())
    }
}

/// Timeline provider for the Upcoming Phases widget.
///
/// Provides moon phase information for upcoming days, refreshing every 6 hours.
struct UpcomingPhasesProvider: TimelineProvider {
    
    // MARK: - TimelineProvider Implementation
    
    func placeholder(in context: Context) -> UpcomingPhasesEntry {
        UpcomingPhasesEntry(date: Date(), phases: previewPhases())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (UpcomingPhasesEntry) -> Void) {
        let phases = generateUpcomingPhases(from: Date())
        completion(UpcomingPhasesEntry(date: Date(), phases: phases))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingPhasesEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        /* Generate entries for each day transition */
        var entries: [UpcomingPhasesEntry] = []
        
        for dayOffset in 0..<9 {
            if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) {
                let phases = generateUpcomingPhases(from: futureDate)
                let entry = UpcomingPhasesEntry(date: futureDate, phases: phases)
                entries.append(entry)
            }
        }
        
        /* Refresh at start of next day */
        let startOfNextDay = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now) ?? now
        )
        
        let timeline = Timeline(entries: entries, policy: .after(startOfNextDay))
        completion(timeline)
    }
    
    // MARK: - Helper Methods
    
    /*
     * Generates phase results for the next 9 days starting from the given date.
     * Individual widget views will determine how many to display based on size.
     */
    private func generateUpcomingPhases(from date: Date) -> [DatePhaseResult] {
        let calendar = Calendar.current
        var phases: [DatePhaseResult] = []
        
        for dayOffset in 0..<9 {
            if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: date) {
                let phaseResult = MoonCalendarGenerator.phase(for: futureDate)
                phases.append(DatePhaseResult(date: futureDate, phase: phaseResult))
            }
        }
        
        return phases
    }
    
    /// Fallback phases for previews
    private func previewPhases() -> [DatePhaseResult] {
        generateUpcomingPhases(from: Date())
    }
}

/// Main view for the Mahina iOS home screen widget.
///
/// Adapts to different widget sizes (small, medium, large) and provides
/// current moon phase information with appropriate visual styling for each size.
struct DayWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    let entry: DayEntry
    
    private var groupRows: [MoonGroupRow] {
        let monthData = MoonCalendarGenerator.buildMonthData(for: entry.date)
        return MoonCalendarGenerator.buildGroupRows(
            monthData: monthData,
            activeDate: entry.date
        )
    }
    
    private var isAccentedRendering: Bool {
        if #available(iOSApplicationExtension 17.0, *) {
            return widgetRenderingMode != .fullColor
        } else {
            return false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if displayModeForFamily == .largeWidget {
                VStack(alignment: .leading, spacing: 8) {
                    DateHeader(date: entry.date, enablePopover: false, isCompact: true)
                    Divider()
                }
                Spacer()
            }
            DayDetail(
                date: entry.date,
                phase: entry.phase,
                displayMode: displayModeForFamily, isAccentedRendering: isAccentedRendering,
                showDescription: displayModeForFamily != .smallWidget
            )
            .animation(.easeInOut(duration: 0.3), value: entry.phase?.primary.day)
            if displayModeForFamily == .largeWidget {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    PhaseGroups(rows: groupRows, isCompact: true)
                }.padding(.bottom, 4)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
        .widgetURL(URL(string: "mahina://today"))
    }
    
    private var displayModeForFamily: DayDetail.DisplayMode {
        switch family {
        case .systemSmall:
            return .smallWidget
        case .systemMedium:
            return .mediumWidget
        case .systemLarge:
            return .largeWidget
        default:
            return .full
        }
    }
}

struct MahinaWidgetExtension: Widget {
    let kind = "MahinaWidgetExtension"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DayWidgetView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Shows today’s moon phase.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}

// MARK: - Today Widget Previews

#Preview("Today (small)", as: .systemSmall) {
    MahinaWidgetExtension()
} timeline: {
    /*
     * Change date string to test specific dates (e.g., "2025-02-27" for transition day)
     */
    DayEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date())
    )
}

#Preview("Today (medium)", as: .systemMedium) {
    MahinaWidgetExtension()
} timeline: {
    /*
     * Change date string to test specific dates (e.g., "2025-02-27" for transition day)
     */
    DayEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date())
    )
}

#Preview("Today (large)", as: .systemLarge) {
    MahinaWidgetExtension()
} timeline: {
    /*
     * Change date string to test specific dates (e.g., "2025-02-27" for transition day)
     */
    DayEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date())
    )
}

// MARK: - Upcoming Phases Widget Views

/// Individual item view for an upcoming phase, showing moon image, date, and phase name.
struct UpcomingPhaseItem: View {
    let datePhase: DatePhaseResult
    let isAccentedRendering: Bool
    let useHorizontalLayout: Bool
    
    private var phase: MoonPhase { datePhase.phase.primary }
    private var isTransitionDay: Bool { datePhase.phase.isTransitionDay }
    
    var body: some View {
        Group {
            if useHorizontalLayout {
                HStack(spacing: 8) {
                    moonImage
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(phase.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    moonImage
                    
                    VStack(spacing: 4) {
                        Text(dateString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(phase.name)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    /*
     * Moon image - use SplitMoonImage for transition days
     */
    @ViewBuilder
    private var moonImage: some View {
        Group {
            if isTransitionDay, let secondary = datePhase.phase.secondary {
                SplitMoonImage(
                    primaryDay: phase.day,
                    secondaryDay: secondary.day,
                    isDetailed: !isAccentedRendering,
                    isAccentedRendering: isAccentedRendering
                )
            } else {
                MoonImage(
                    day: phase.day,
                    isDetailed: !isAccentedRendering,
                    isAccentedRendering: isAccentedRendering
                )
            }
        }
        .frame(width: 40, height: 40)
    }
    
    private var dateString: String {
        let day = Calendar.current.component(.day, from: datePhase.date)
        let month = HawaiianLocalization.month(for: datePhase.date) ?? englishMonth
        return "\(month) \(day)"
    }
    
    private var englishMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM"
        return formatter.string(from: datePhase.date)
    }
}

/// Main widget view for Upcoming Phases, adapting to different widget sizes.
struct UpcomingPhasesWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    let entry: UpcomingPhasesEntry
    
    private var isAccentedRendering: Bool {
        if #available(iOSApplicationExtension 17.0, *) {
            return widgetRenderingMode != .fullColor
        } else {
            return false
        }
    }
    
    /*
     * Determine how many phases to show based on widget size:
     * - Small: 2 phases (today + tomorrow)
     * - Medium: 3 phases
     * - Large: 9 phases
     */
    private var phasesToShow: [DatePhaseResult] {
        let count: Int
        switch family {
        case .systemSmall:
            count = 2
        case .systemMedium:
            count = 3
        case .systemLarge:
            count = 9
        default:
            count = 2
        }
        return Array(entry.phases.prefix(count))
    }
    
    /*
     * Grid columns configuration based on widget size
     */
    private var gridColumns: [GridItem] {
        let columnCount = family == .systemLarge ? 3 : phasesToShow.count
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(family == .systemSmall ? "Today & Tomorrow" : "Upcoming Phases")
                .font(family == .systemSmall ? .caption : .headline)
                .fontWeight(.semibold)
            
            Divider()
            
            if family == .systemSmall {
                VStack(spacing: 12) {
                    ForEach(phasesToShow) { datePhase in
                        Link(destination: dateURL(for: datePhase.date)) {
                            UpcomingPhaseItem(
                                datePhase: datePhase,
                                isAccentedRendering: isAccentedRendering,
                                useHorizontalLayout: true
                            )
                        }
                    }
                }
            } else if family == .systemMedium {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(phasesToShow) { datePhase in
                        Link(destination: dateURL(for: datePhase.date)) {
                            UpcomingPhaseItem(
                                datePhase: datePhase,
                                isAccentedRendering: isAccentedRendering,
                                useHorizontalLayout: false
                            )
                        }
                    }
                }
            } else {
                /* Large widget: show grid with individually tappable phases */
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(phasesToShow) { datePhase in
                        Link(destination: dateURL(for: datePhase.date)) {
                            UpcomingPhaseItem(
                                datePhase: datePhase,
                                isAccentedRendering: isAccentedRendering,
                                useHorizontalLayout: false
                            )
                        }
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    /*
     * Generates URL for navigating to a specific date
     */
    private func dateURL(for date: Date) -> URL {
        let dateString = ISO8601DateFormatter().string(from: date)
        return URL(string: "mahina://date/\(dateString)")!
    }
}

struct UpcomingPhasesWidget: Widget {
    let kind = "UpcomingPhasesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingPhasesProvider()) { entry in
            UpcomingPhasesWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Phases")
        .description("Shows upcoming moon phases.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}

// MARK: - Upcoming Phases Widget Previews

#Preview("Upcoming (small)", as: .systemSmall) {
    UpcomingPhasesWidget()
} timeline: {
    let today = Date()
    let calendar = Calendar.current
    let phases = (0..<2).compactMap { offset -> DatePhaseResult? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let phase = MoonCalendarGenerator.phase(for: date)
        return DatePhaseResult(date: date, phase: phase)
    }
    UpcomingPhasesEntry(date: today, phases: phases)
}

#Preview("Upcoming (medium)", as: .systemMedium) {
    UpcomingPhasesWidget()
} timeline: {
    let today = Date()
    let calendar = Calendar.current
    let phases = (0..<3).compactMap { offset -> DatePhaseResult? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let phase = MoonCalendarGenerator.phase(for: date)
        return DatePhaseResult(date: date, phase: phase)
    }
    UpcomingPhasesEntry(date: today, phases: phases)
}

#Preview("Upcoming (large)", as: .systemLarge) {
    UpcomingPhasesWidget()
} timeline: {
    let today = Date()
    let calendar = Calendar.current
    let phases = (0..<9).compactMap { offset -> DatePhaseResult? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let phase = MoonCalendarGenerator.phase(for: date)
        return DatePhaseResult(date: date, phase: phase)
    }
    UpcomingPhasesEntry(date: today, phases: phases)
}
