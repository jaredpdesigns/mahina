import WidgetKit
import SwiftUI
import MahinaAssets

/// Timeline provider for Apple Watch complications displaying current moon phase information.
///
/// Updates daily to show the current lunar phase on various watch face complications.
/// Provides appropriate visual representations for different complication families and sizes.
struct MoonComplicationProvider: TimelineProvider {

    // MARK: - TimelineProvider Implementation
    func placeholder(in context: Context) -> MoonComplicationEntry {
        sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MoonComplicationEntry) -> ()) {
        completion(sampleEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoonComplicationEntry>) -> ()) {
        let now = Date()
        let entry = entry(for: now)

        // Update again at the start of the next day since the visible phase changes slowly.
        let cal = Calendar.current
        let startOfNextDay = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        let timeline = Timeline(entries: [entry], policy: .after(startOfNextDay))
        completion(timeline)
    }

    // MARK: - Helper Methods

    private func sampleEntry() -> MoonComplicationEntry {
        entry(for: Date())
    }

    private func entry(for date: Date) -> MoonComplicationEntry {
        let phaseResult = MoonCalendarGenerator.phase(for: date)
        return MoonComplicationEntry(
            date: date,
            phase: phaseResult.primary
        )
    }
}

struct MoonComplicationEntry: TimelineEntry {
    /// The date for the timeline entry (required by TimelineEntry).
    let date: Date
    /// The moon phase to display, as used elsewhere in the app.
    let phase: MoonPhase
}

struct MahinaComplicationsEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MoonComplicationEntry

    var body: some View {
        switch family {

        case .accessoryCorner:
            /*
             * Corner complication: curved text label with moon image
             */
            ZStack {
                AccessoryWidgetBackground()
                moonImage(for: entry.phase.day)
                    .resizable()
                    .renderingMode(.template)
                    .widgetAccentable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            }
            .widgetLabel {
                Text(entry.phase.name)
            }

        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 16) {
                moonImage(for: entry.phase.day)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                DateHeader(date: entry.date)
            }

        case .accessoryInline:
            /*
             * Inline complication: text only (no images supported)
             */
            Label {
                Text(entry.phase.name)
            } icon: {
                Image(systemName: "moon.fill")
            }

        case .accessoryCircular:
            /*
             * Circular complication: moon image only
             */
            ZStack {
                AccessoryWidgetBackground()
                moonImage(for: entry.phase.day)
                    .resizable()
                    .renderingMode(.template)
                    .widgetAccentable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            }

        default:
            moonImage(for: entry.phase.day)
                .resizable()
                .renderingMode(.template)
                .widgetAccentable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
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
        .configurationDisplayName("Mahina Moon")
        .description("Shows today's moon phase.")
        .supportedFamilies([
            .accessoryCorner,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview("Rectangular", as: .accessoryRectangular) {
    MahinaComplications()
} timeline: {
    MoonComplicationEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date()).primary
    )
    MoonComplicationEntry(
        date: Date(),
        phase: MoonCalendarGenerator.phase(for: Date()).primary
    )
}
