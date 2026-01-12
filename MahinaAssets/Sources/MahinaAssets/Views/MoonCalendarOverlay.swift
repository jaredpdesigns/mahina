import SwiftUI
import Foundation

public struct MoonCalendarOverlay: View {
    public let initialMonth: Date
    public let initialActiveDate: Date
    public var onSelect: (Date, Date) -> Void
@State public var monthAnchor: Date
@State public var selection: Date
    
    public init(initialMonth: Date, initialActiveDate: Date, onSelect: @escaping (Date, Date) -> Void) {
        self.initialMonth = initialMonth
        self.initialActiveDate = initialActiveDate
        self.onSelect = onSelect
        _monthAnchor = State(initialValue: initialMonth)
        _selection = State(initialValue: initialActiveDate)
    }
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: monthAnchor)
    }
    
    public var body: some View {
        MoonCalendar(
            monthData: monthData,
            displayedMonth: $monthAnchor,
            activeDate: $selection
        )
        .padding()
        .accessibilityLabel("Month picker")
        .accessibilityHint("Select a date to view its lunar phase")
        .onChange(of: selection) { _, newValue in
            onSelect(newValue, monthAnchor)
        }
    }
}
