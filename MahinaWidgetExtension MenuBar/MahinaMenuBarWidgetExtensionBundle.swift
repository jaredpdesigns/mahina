import WidgetKit
import SwiftUI
import MahinaAssets

@main
struct MahinaMenuBarWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        MahinaMenuBarTodayWidget()
        MahinaMenuBarUpcomingPhasesWidget()
    }
}
