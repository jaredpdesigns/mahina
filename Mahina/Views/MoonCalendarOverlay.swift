import SwiftUI
import Foundation

struct MoonCalendarOverlay: View {
    let initialMonth: Date
    let initialActiveDate: Date
    var onSelect: (Date, Date) -> Void
    @State private var monthAnchor: Date
    @State private var selection: Date
    
    init(initialMonth: Date, initialActiveDate: Date, onSelect: @escaping (Date, Date) -> Void) {
        self.initialMonth = initialMonth
        self.initialActiveDate = initialActiveDate
        self.onSelect = onSelect
        _monthAnchor = State(initialValue: initialMonth)
        _selection = State(initialValue: initialActiveDate)
    }
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: monthAnchor)
    }
    
    var body: some View {
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
