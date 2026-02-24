#if os(iOS) || os(macOS)

import SwiftUI
import WidgetKit

// MARK: - Shared Timeline Entries

public struct WidgetDayEntry: TimelineEntry {
    public let date: Date
    public let phase: PhaseResult?
    
    public init(date: Date, phase: PhaseResult?) {
        self.date = date
        self.phase = phase
    }
}

public struct WidgetUpcomingPhasesEntry: TimelineEntry {
    public let date: Date
    public let phases: [WidgetDatePhaseResult]
    
    public init(date: Date, phases: [WidgetDatePhaseResult]) {
        self.date = date
        self.phases = phases
    }
}

public struct WidgetDatePhaseResult: Identifiable {
    public let id = UUID()
    public let date: Date
    public let phase: PhaseResult
    
    public init(date: Date, phase: PhaseResult) {
        self.date = date
        self.phase = phase
    }
}

// MARK: - Shared Timeline Providers

public struct WidgetDayProvider: TimelineProvider {
    
    public init() {}
    
    public func placeholder(in context: Context) -> WidgetDayEntry {
        WidgetDayEntry(date: Date(), phase: MoonCalendarGenerator.phase(for: Date()))
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WidgetDayEntry) -> Void) {
        completion(WidgetDayEntry(date: Date(), phase: MoonCalendarGenerator.phase(for: Date())))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetDayEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        let todayEntry = WidgetDayEntry(date: now, phase: MoonCalendarGenerator.phase(for: now))
        
        let startOfNextDay = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now) ?? now
        )
        
        completion(Timeline(entries: [todayEntry], policy: .after(startOfNextDay)))
    }
}

public struct WidgetUpcomingPhasesProvider: TimelineProvider {
    
    public init() {}
    
    public func placeholder(in context: Context) -> WidgetUpcomingPhasesEntry {
        WidgetUpcomingPhasesEntry(date: Date(), phases: generateUpcomingPhases(from: Date()))
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WidgetUpcomingPhasesEntry) -> Void) {
        completion(WidgetUpcomingPhasesEntry(date: Date(), phases: generateUpcomingPhases(from: Date())))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetUpcomingPhasesEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        var entries: [WidgetUpcomingPhasesEntry] = []
        
        for dayOffset in 0..<9 {
            if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) {
                let entry = WidgetUpcomingPhasesEntry(
                    date: futureDate,
                    phases: generateUpcomingPhases(from: futureDate)
                )
                entries.append(entry)
            }
        }
        
        let startOfNextDay = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now) ?? now
        )
        
        completion(Timeline(entries: entries, policy: .after(startOfNextDay)))
    }
    
    /*
     * Generates phase results for the next 9 days starting from the given date.
     * Individual widget views determine how many to display based on size.
     */
    private func generateUpcomingPhases(from date: Date) -> [WidgetDatePhaseResult] {
        let calendar = Calendar.current
        var phases: [WidgetDatePhaseResult] = []
        
        for dayOffset in 0..<9 {
            if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: date) {
                phases.append(WidgetDatePhaseResult(
                    date: futureDate,
                    phase: MoonCalendarGenerator.phase(for: futureDate)
                ))
            }
        }
        
        return phases
    }
}

// MARK: - Shared Widget Views

public struct WidgetDayView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    public let entry: WidgetDayEntry
    
    public init(entry: WidgetDayEntry) {
        self.entry = entry
    }
    
    private var groupRows: [MoonGroupRow] {
        let monthData = MoonCalendarGenerator.buildMonthData(for: entry.date)
        return MoonCalendarGenerator.buildGroupRows(
            monthData: monthData,
            activeDate: entry.date
        )
    }
    
    private var isAccentedRendering: Bool {
        widgetRenderingMode != .fullColor
    }
    
    public var body: some View {
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
                showDescription: displayModeForFamily != .smallWidget,
                showTransitionIndicator: false
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

public struct WidgetUpcomingPhaseItem: View {
    public let datePhase: WidgetDatePhaseResult
    public let isAccentedRendering: Bool
    public let useHorizontalLayout: Bool
    
    public init(datePhase: WidgetDatePhaseResult, isAccentedRendering: Bool, useHorizontalLayout: Bool) {
        self.datePhase = datePhase
        self.isAccentedRendering = isAccentedRendering
        self.useHorizontalLayout = useHorizontalLayout
    }
    
    private var phase: MoonPhase { datePhase.phase.primary }
    private var isTransitionDay: Bool { datePhase.phase.isTransitionDay }
    
    public var body: some View {
        Group {
            if useHorizontalLayout {
                HStack(spacing: 8) {
                    moonImage
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        phaseLabel(captionSized: true)
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
                        phaseLabel(captionSized: false)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func phaseLabel(captionSized: Bool) -> some View {
        if isTransitionDay, let secondary = datePhase.phase.secondary {
            HStack(spacing: 2) {
                Text(phase.name)
                    .font(captionSized ? .caption : nil)
                    .fontWeight(.semibold)
                Text("→")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(secondary.name)
                    .font(captionSized ? .caption : nil)
                    .fontWeight(.semibold)
            }
        } else {
            Text(phase.name)
                .font(captionSized ? .caption : nil)
                .fontWeight(.semibold)
        }
    }
    
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

public struct WidgetUpcomingPhasesView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    public let entry: WidgetUpcomingPhasesEntry
    
    public init(entry: WidgetUpcomingPhasesEntry) {
        self.entry = entry
    }
    
    private var isAccentedRendering: Bool {
        widgetRenderingMode != .fullColor
    }
    
    /*
     * Determine how many phases to show based on widget size:
     * - Small: 2 phases (today + tomorrow)
     * - Medium: 3 phases
     * - Large: 9 phases
     */
    private var phasesToShow: [WidgetDatePhaseResult] {
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
    
    private var gridColumns: [GridItem] {
        let columnCount = family == .systemLarge ? 3 : phasesToShow.count
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(family == .systemSmall ? "Today & Tomorrow" : "Upcoming Phases")
                .font(family == .systemSmall ? .caption : .headline)
                .fontWeight(.semibold)
            
            Divider()
            
            if family == .systemSmall {
                VStack(spacing: 12) {
                    ForEach(phasesToShow) { datePhase in
                        Link(destination: dateURL(for: datePhase.date)) {
                            WidgetUpcomingPhaseItem(
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
                            WidgetUpcomingPhaseItem(
                                datePhase: datePhase,
                                isAccentedRendering: isAccentedRendering,
                                useHorizontalLayout: false
                            )
                        }
                    }
                }
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(phasesToShow) { datePhase in
                        Link(destination: dateURL(for: datePhase.date)) {
                            WidgetUpcomingPhaseItem(
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
    
    private func dateURL(for date: Date) -> URL {
        let dateString = ISO8601DateFormatter().string(from: date)
        return URL(string: "mahina://date/\(dateString)")!
    }
}

// MARK: - Today Widget Previews

#Preview("Today (small)") {
    WidgetDayView(entry: WidgetDayEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date())
    ))
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Today (medium)") {
    WidgetDayView(entry: WidgetDayEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date())
    ))
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}

#Preview("Today (large)") {
    WidgetDayView(entry: WidgetDayEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date())
    ))
    .previewContext(WidgetPreviewContext(family: .systemLarge))
}

// MARK: - Upcoming Phases Widget Previews

private func previewPhases(count: Int) -> [WidgetDatePhaseResult] {
    let today = Date()
    let calendar = Calendar.current
    return (0..<count).compactMap { offset in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        return WidgetDatePhaseResult(date: date, phase: MoonCalendarGenerator.phase(for: date))
    }
}

#Preview("Upcoming (small)") {
    WidgetUpcomingPhasesView(entry: WidgetUpcomingPhasesEntry(
        date: Date(),
        phases: previewPhases(count: 2)
    ))
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Upcoming (medium)") {
    WidgetUpcomingPhasesView(entry: WidgetUpcomingPhasesEntry(
        date: Date(),
        phases: previewPhases(count: 3)
    ))
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}

#Preview("Upcoming (large)") {
    WidgetUpcomingPhasesView(entry: WidgetUpcomingPhasesEntry(
        date: Date(),
        phases: previewPhases(count: 9)
    ))
    .previewContext(WidgetPreviewContext(family: .systemLarge))
}

#endif
