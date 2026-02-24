import MahinaAssets
import SwiftUI
import WidgetKit

struct MahinaWidgetExtension: Widget {
    let kind = "MahinaWidgetExtension"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetDayProvider()) { entry in
            WidgetDayView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Shows today's moon phase.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}

struct UpcomingPhasesWidget: Widget {
    let kind = "UpcomingPhasesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetUpcomingPhasesProvider()) { entry in
            WidgetUpcomingPhasesView(entry: entry)
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

// MARK: - Today Widget Previews

#Preview("Today (small)", as: .systemSmall) {
    MahinaWidgetExtension()
} timeline: {
    let today = Date()
    
    WidgetDayEntry(
        date: today,
        phase: MoonCalendarGenerator.phase(for: today)
    )
}

#Preview("Today (medium)", as: .systemMedium) {
    MahinaWidgetExtension()
} timeline: {
    let today = Date()
    
    WidgetDayEntry(
        date: today,
        phase: MoonCalendarGenerator.phase(for: today)
    )
}

#Preview("Today (large)", as: .systemLarge) {
    MahinaWidgetExtension()
} timeline: {
    let today = Date()
    
    WidgetDayEntry(
        date: today,
        phase: MoonCalendarGenerator.phase(for: today)
    )
}

// MARK: - Upcoming Phases Widget Previews

#Preview("Upcoming (small)", as: .systemSmall) {
    UpcomingPhasesWidget()
} timeline: {
    let today = Date()
    let calendar = Calendar.current
    let phases = (0..<2).compactMap { offset -> WidgetDatePhaseResult? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let phase = MoonCalendarGenerator.phase(for: date)
        return WidgetDatePhaseResult(date: date, phase: phase)
    }
    WidgetUpcomingPhasesEntry(date: today, phases: phases)
}

#Preview("Upcoming (medium)", as: .systemMedium) {
    UpcomingPhasesWidget()
} timeline: {
    let today = Date()
    let calendar = Calendar.current
    let phases = (0..<3).compactMap { offset -> WidgetDatePhaseResult? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let phase = MoonCalendarGenerator.phase(for: date)
        return WidgetDatePhaseResult(date: date, phase: phase)
    }
    WidgetUpcomingPhasesEntry(date: today, phases: phases)
}

#Preview("Upcoming (large)", as: .systemLarge) {
    UpcomingPhasesWidget()
} timeline: {
    let today = Date()
    let calendar = Calendar.current
    let phases = (0..<9).compactMap { offset -> WidgetDatePhaseResult? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let phase = MoonCalendarGenerator.phase(for: date)
        return WidgetDatePhaseResult(date: date, phase: phase)
    }
    WidgetUpcomingPhasesEntry(date: today, phases: phases)
}
