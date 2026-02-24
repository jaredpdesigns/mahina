import MahinaAssets
import SwiftUI
import WidgetKit

struct MahinaMenuBarTodayWidget: Widget {
    let kind = "MahinaMenuBarTodayWidget"
    
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

struct MahinaMenuBarUpcomingPhasesWidget: Widget {
    let kind = "MahinaMenuBarUpcomingPhasesWidget"
    
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
