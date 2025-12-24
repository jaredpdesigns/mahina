import SwiftUI

/// PhaseGroups component with integrated popover functionality.
///
/// Displays the three Hawaiian lunar phase groups with tap-to-view-details functionality.
/// Manages its own state for showing group information popovers.
struct PhaseGroupsWithPopover: View {
    let rows: [MoonGroupRow]
    var isVertical: Bool = false
    
    @State private var selectedGroupRow: MoonGroupRow?
    
    var body: some View {
        PhaseGroups(rows: rows, onSelectRow:  { row in
            selectedGroupRow = row
        }, isVertical: isVertical)
        .animation(nil, value: rows)
        .accessibilityLabel("Moon phase groups")
        .accessibilityHint("Shows progress through lunar cycle")
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
    }
}

/// Popover content showing detailed information about a moon phase group.
private struct MoonGroupInfoPopoverView: View {
    let name: String
    let description: String
    let englishMeaning: String
    
    var body: some View {
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

