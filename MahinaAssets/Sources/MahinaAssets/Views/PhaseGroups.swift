import SwiftUI

/// Visual representation of the three Hawaiian lunar phase groups (Hoʻonui, Poepoe, Emi).
///
/// Displays progress through each group using circular charts (compact mode) or capsule
/// indicators (expanded mode) that show completion status relative to the current lunar day.
public struct PhaseGroups: View {
    // MARK: - Properties
    
    public let rows: [MoonGroupRow]
    /// Callback when a group row is tapped for more information
    public var onSelectRow: (MoonGroupRow) -> Void = { _ in }
    /// Whether to display in compact mode (circular charts) or expanded mode (capsules)
    public var isCompact: Bool = false
    
    public init(
        rows: [MoonGroupRow], onSelectRow: @escaping (MoonGroupRow) -> Void = { _ in },
        isCompact: Bool = false
    ) {
        self.rows = rows
        self.onSelectRow = onSelectRow
        self.isCompact = isCompact
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Moon groups progress")
    }
    
    // MARK: - View Components
    
    /// Adaptive layout that switches between compact and expanded arrangements
    @ViewBuilder
    private var content: some View {
        HStack(spacing: 24) {
            pills
        }
    }
    
    /// Collection of interactive group pills showing phase progress
    private var pills: some View {
        ForEach(rows.indices, id: \.self) { index in
            let row = rows[index]
            
            Button {
                onSelectRow(row)
            } label: {
                PhaseGroupRowView(row: row, isCompact: isCompact)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Single group row with label and progress indicators for each calendar day in that group.
private struct PhaseGroupRowView: View {
    let row: MoonGroupRow
    let isCompact: Bool
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(row.name)
                .font(
                    .caption
                        .weight(row.isActiveGroup ? .semibold : .regular)
                )
                .textCase(.uppercase)
                .opacity(row.isActiveGroup ? 1.0 : 0.75)
            
            FlowDotsView(days: row.days, isCompact: isCompact)
                .padding(.leading, isCompact ? 8 : 0)
                .padding(.top, isCompact ? 4 : 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.name) moon group")
        .accessibilityValue(row.isActiveGroup ? "Currently active group" : "Inactive group")
        .accessibilityHint("Tap to view group description")
    }
}

/// Displays lunar day progress as either a circular chart (compact) or capsules (expanded)
private struct FlowDotsView: View {
    let days: [MoonGroupRow.Day]
    let isCompact: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public var body: some View {
        if isCompact {
            CircularSegmentChart(days: days)
        } else {
            HStack(spacing: 4) {
                ForEach(days) { day in
                    Capsule()
                        .frame(width: 6, height: 24)
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

/// Circular gauge showing progress through lunar days in the group
private struct CircularSegmentChart: View {
    let days: [MoonGroupRow.Day]
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Gauge(value: Double(filledDaysCount), in: 0...Double(totalDays)) {
            EmptyView()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Circular progress chart")
        .accessibilityValue("\(filledDaysCount) of \(totalDays) days completed")
        .scaleEffect(0.8)
        .frame(width: 32, height: 32)
    }
    
    private var filledDaysCount: Int {
        days.filter(\.isFilled).count
    }
    
    private var totalDays: Int {
        days.count
    }
}


#Preview {
    let today = Date()
    let rows: [MoonGroupRow] = {
        let monthData = MoonCalendarGenerator.buildMonthData(for: today)
        return MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: today)
    }()
    
    VStack(alignment: .leading, spacing: 40) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compact Mode (Circular Gauges)")
                .font(.headline)
            PhaseGroups(rows: rows, isCompact: true)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Expanded Mode (Capsules)")
                .font(.headline)
            PhaseGroups(rows: rows, isCompact: false)
        }
    }
    .padding()
}
