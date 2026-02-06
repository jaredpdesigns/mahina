import MahinaAssets
import SwiftUI
import WidgetKit

/// Timeline entry for the Mahina widget containing moon phase information for a specific date
struct DayEntry: TimelineEntry {
    let date: Date
    let phase: PhaseResult?
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
        let today = Date()
        let phaseResult = MoonCalendarGenerator.phase(for: today)

        // Refresh every 6 hours
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: today)!

        let entry = DayEntry(date: today, phase: phaseResult)
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }

    // MARK: - Helper Methods

    /// Fallback phase for previews if no data available
    private func previewPhase() -> PhaseResult? {
        MoonCalendarGenerator.phase(for: Date())
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
            DayDetail(
                date: entry.date,
                phase: entry.phase,
                displayMode: displayModeForFamily, isAccentedRendering: isAccentedRendering,
                showDescription: displayModeForFamily != .smallWidget
            )
            if displayModeForFamily == .largeWidget {
                Spacer()
                Divider()
                PhaseGroups(rows: groupRows, isVertical: true)
                    .padding(.top)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
        .padding(.bottom, displayModeForFamily == .largeWidget ? 16 : 0)
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

#Preview(as: .systemLarge) {
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
