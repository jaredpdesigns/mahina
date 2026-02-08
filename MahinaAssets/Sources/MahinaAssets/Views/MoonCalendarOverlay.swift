import Foundation
import SwiftUI

public struct MoonCalendarOverlay: View {
    public let initialMonth: Date
    public let initialActiveDate: Date
    public var enablePopover: Bool = true
    public var onSelect: (Date, Date) -> Void
    @State public var monthAnchor: Date
    @State public var selection: Date
    
    public init(
        initialMonth: Date, initialActiveDate: Date, enablePopover: Bool = true,
        onSelect: @escaping (Date, Date) -> Void
    ) {
        self.initialMonth = initialMonth
        self.initialActiveDate = initialActiveDate
        self.enablePopover = enablePopover
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
            activeDate: $selection,
            enablePopover: enablePopover
        )
        .padding()
        .accessibilityLabel("Month picker")
        .accessibilityHint("Select a date to view its lunar phase")
        .onChange(of: selection) { _, newValue in
            onSelect(newValue, monthAnchor)
        }
    }
}
