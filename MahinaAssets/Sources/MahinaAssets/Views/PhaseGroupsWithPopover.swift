import SwiftUI

/// PhaseGroups component with integrated popover functionality.
///
/// Displays the three Hawaiian lunar phase groups with tap-to-view-details functionality.
/// Manages its own state for showing group information popovers.
public struct PhaseGroupsWithPopover: View {
    public let rows: [MoonGroupRow]
    public var isVertical: Bool = false

    public init(rows: [MoonGroupRow], isVertical: Bool = false) {
        self.rows = rows
        self.isVertical = isVertical
    }

    @State public var selectedGroupRow: MoonGroupRow?

    public var body: some View {
        PhaseGroups(
            rows: rows,
            onSelectRow: { row in
                selectedGroupRow = row
            }, isVertical: isVertical
        )
        .animation(nil, value: rows)
        .accessibilityLabel("Moon phase groups")
        .accessibilityHint("Shows progress through lunar cycle")
        #if !os(watchOS)
            .popover(
                item: $selectedGroupRow,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .bottom
            ) { row in
                MoonGroupInfoPopoverView(
                    name: row.name,
                    description: row.description,
                    englishMeaning: row.englishMeaning
                )
                .frame(width: 360)
                .presentationCompactAdaptation(.popover)
            }
        #endif
    }
}

/// Popover content showing detailed information about a moon phase group.
private struct MoonGroupInfoPopoverView: View {
    let name: String
    let description: String
    let englishMeaning: String

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(name) (\(englishMeaning))")
                .fontWeight(.semibold)
            Text(description)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let today = Date()
    let rows: [MoonGroupRow] = {
        let monthData = MoonCalendarGenerator.buildMonthData(for: today)
        return MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: today)
    }()
    return PhaseGroupsWithPopover(rows: rows)
        .padding()
}
