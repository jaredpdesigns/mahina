import SwiftUI

/// Visual representation of the three Hawaiian lunar phase groups (Hoʻonui, Poepoe, Emi).
///
/// Displays progress through each group using pill-shaped indicators that show completion
/// status relative to the current lunar day. Supports both horizontal and vertical layouts.
public struct PhaseGroups: View {
    // MARK: - Properties
    
    public let rows: [MoonGroupRow]
    /// Callback when a group row is tapped for more information
    public var onSelectRow: (MoonGroupRow) -> Void = { _ in }
    /// Whether to display groups vertically or horizontally
    public var isVertical: Bool = false
    
    public init(
        rows: [MoonGroupRow], onSelectRow: @escaping (MoonGroupRow) -> Void = { _ in },
        isVertical: Bool = false
    ) {
        self.rows = rows
        self.onSelectRow = onSelectRow
        self.isVertical = isVertical
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Moon groups progress")
    }
    
    // MARK: - View Components
    
    /// Adaptive layout that switches between horizontal and vertical arrangements
    @ViewBuilder
    private var content: some View {
        if isVertical {
            VStack(alignment: .leading, spacing: 8) {
                pills
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 24) {
                pills
            }
        }
    }
    
    /// Collection of interactive group pills showing phase progress
    private var pills: some View {
        ForEach(rows.indices, id: \.self) { index in
            let row = rows[index]
            
            Button {
                onSelectRow(row)
            } label: {
                PhaseGroupRowView(row: row, isVertical: isVertical)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Single group row with label and progress dots/bars for each calendar day in that group.
private struct PhaseGroupRowView: View {
    let row: MoonGroupRow
    let isVertical: Bool
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(row.name)
                .font(
                    .caption
                        .weight(row.isActiveGroup ? .semibold : .regular)
                )
                .textCase(.uppercase)
                .opacity(row.isActiveGroup ? 1.0 : 0.75)
            
            FlowDotsView(days: row.days, isVertical: isVertical)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.name) moon group")
        .accessibilityValue(row.isActiveGroup ? "Currently active group" : "Inactive group")
        .accessibilityHint("Tap to view group description")
    }
}

/// Horizontal series of small capsules indicating fill state for each day in the group.
private struct FlowDotsView: View {
    let days: [MoonGroupRow.Day]
    let isVertical: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(days) { day in
                Capsule()
                    .frame(width: isVertical ? 12 : 6, height: isVertical ? 12 : 24)
                    .opacity(day.isFilled ? 1 : 0.25)
                    .foregroundStyle(capsuleForegroundColor)
                    .accessibilityLabel("Lunar day \(day.lunarDay)")
                    .accessibilityValue(day.isFilled ? "Completed" : "Pending")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Group progress indicators")
        .accessibilityValue("\(days.filter(\.isFilled).count) of \(days.count) days completed")
    }
    
    private var capsuleForegroundColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .black
        }
    }
}

#Preview {
    let today = Date()
    let rows: [MoonGroupRow] = {
        let monthData = MoonCalendarGenerator.buildMonthData(for: today)
        return MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: today)
    }()
    return PhaseGroups(rows: rows).padding()
}
