import MahinaAssets
import SwiftUI
import WidgetKit

/// Timeline provider for Apple Watch complications displaying current moon phase information.
///
/// Updates daily to show the current lunar phase on various watch face complications.
/// Provides appropriate visual representations for different complication families and sizes.
struct MoonComplicationProvider: TimelineProvider {

    // MARK: - TimelineProvider Implementation
    func placeholder(in context: Context) -> MoonComplicationEntry {
        sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MoonComplicationEntry) -> Void) {
        completion(sampleEntry())
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<MoonComplicationEntry>) -> Void
    ) {
        let now = Date()
        let entry = entry(for: now)

        // Update again at the start of the next day since the visible phase changes slowly.
        let cal = Calendar.current
        let startOfNextDay = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        let timeline = Timeline(entries: [entry], policy: .after(startOfNextDay))
        completion(timeline)
    }

    // MARK: - Helper Methods

    /// Returns a static placeholder entry with day 30 (Muku - new moon)
    private func sampleEntry() -> MoonComplicationEntry {
        let phase = MoonCalendarGenerator.moonPhase(for: 30)
        return MoonComplicationEntry(
            date: Date(),
            phaseResult: PhaseResult(primary: phase)
        )
    }

    private func entry(for date: Date) -> MoonComplicationEntry {
        let phaseResult = MoonCalendarGenerator.phase(for: date)
        return MoonComplicationEntry(
            date: date,
            phaseResult: phaseResult
        )
    }
}

struct MoonComplicationEntry: TimelineEntry {
    /// The date for the timeline entry (required by TimelineEntry).
    let date: Date
    /// The complete phase result including primary, secondary, and transition info.
    let phaseResult: PhaseResult

    /// Convenience accessor for the primary phase.
    var phase: MoonPhase { phaseResult.primary }
    /// Convenience accessor for the secondary phase on transition days.
    var secondaryPhase: MoonPhase? { phaseResult.secondary }
    /// Whether this is a transition day with overlapping phases.
    var isTransitionDay: Bool { phaseResult.isTransitionDay }
}

struct MahinaComplicationsEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    var entry: MoonComplicationEntry

    /*
     * Accented rendering mode applies to "Clear" watch face styles
     */
    private var isAccentedRendering: Bool {
        if #available(watchOSApplicationExtension 10.0, *) {
            return widgetRenderingMode != .fullColor
        } else {
            return false
        }
    }

    /// Returns the appropriate moon view - follows DayDetail.headerImage pattern
    @ViewBuilder
    private func moonView(
        for entry: MoonComplicationEntry,
        isDetailed: Bool = true
    ) -> some View {
        if entry.isTransitionDay, let secondaryPhase = entry.secondaryPhase {
            SplitMoonImage(
                primaryDay: entry.phase.day,
                secondaryDay: secondaryPhase.day,
                isDetailed: isDetailed,
                isAccentedRendering: isAccentedRendering
            )
            .unredacted()
            .opacity(isLuminanceReduced ? 0.5 : 1.0)
        } else {
            MoonImage(
                day: entry.phase.day,
                isDetailed: isDetailed,
                isAccentedRendering: isAccentedRendering
            )
            .unredacted()
            .opacity(isLuminanceReduced ? 0.5 : 1.0)
        }
    }

    var body: some View {
        switch family {

        case .accessoryCorner:
            ZStack {
                AccessoryWidgetBackground()
                moonView(
                    for: entry,
                    isDetailed: false
                )
                .widgetAccentable()
                .padding(4)
            }
            .widgetLabel {
                Text(entry.phase.name)
            }

        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 16) {
                moonView(for: entry)
                    .widgetAccentable()
                    .frame(width: 36, height: 36)
                ComplicationDatePhaseHeader(date: entry.date, phase: entry.phase)
            }

        case .accessoryInline:
            Label {
                Text(entry.phase.name)
            } icon: {
                Image(systemName: "moon.fill")
            }

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                moonView(
                    for: entry,
                    isDetailed: false
                )
                .widgetAccentable()
                .frame(width: 36, height: 36)
            }

        default:
            EmptyView()
        }
    }
}

struct MahinaComplications: Widget {
    let kind: String = "MahinaComplications"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoonComplicationProvider()) { entry in
            if #available(watchOS 10.0, *) {
                MahinaComplicationsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MahinaComplicationsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Mahina")
        .description("Shows today's moon phase.")
        .supportedFamilies([
            .accessoryCorner,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Complication-Specific Views

/// Date and phase header specifically designed for rectangular complications
private struct ComplicationDatePhaseHeader: View {
    let date: Date
    let phase: MoonPhase

    private var dateString: String {
        let day = Calendar.current.component(.day, from: date)
        let month = HawaiianLocalization.month(for: date) ?? englishMonth
        return "\(month) \(day)"  // Hawaiian month + day for compact display
    }

    private var englishMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM"  // Full month name
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateString)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(phase.name)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)  // White in dark mode, black in light mode
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview("Rectangular", as: .accessoryRectangular) {
    MahinaComplications()
} timeline: {
    let date = Date()

    MoonComplicationEntry(
        date: date,
        phaseResult: MoonCalendarGenerator.phase(for: date)
    )
}

#Preview("Circular", as: .accessoryCircular) {
    MahinaComplications()
} timeline: {
    let date = Date()

    MoonComplicationEntry(
        date: date,
        phaseResult: MoonCalendarGenerator.phase(for: date)
    )
}

#Preview("Corner", as: .accessoryCorner) {
    MahinaComplications()
} timeline: {
    let date = Date()

    MoonComplicationEntry(
        date: date,
        phaseResult: MoonCalendarGenerator.phase(for: date)
    )
}
