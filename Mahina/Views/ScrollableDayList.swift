import SwiftUI

/// Preference key for tracking scroll positions of day items in the list
struct DayPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Invisible view that tracks and reports the vertical position of a day item in the scroll view
struct DayPositionTracker: View {
    let date: Date

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("scroll"))
            Color.clear.preference(
                key: DayPositionPreferenceKey.self,
                value: [date: frame.minY]
            )
        }
    }
}

/// Generic scrollable list with automatic scrolling and active date tracking.
///
/// Provides a vertically scrollable list of items with automatic scroll-to-date functionality.
/// Tracks which day is currently in the center of the view and updates the active date accordingly.
/// Includes position tracking for smooth programmatic scrolling to specific dates.
struct ScrollableDayList<Item, RowContent: View, BottomContent: View>: View {
    // MARK: - Properties

    let items: [Item]
    @Binding var activeDate: Date
    @Binding var scrollTarget: Date?

    /// Function to extract date from each item
    let dateForItem: (Item) -> Date
    /// View builder for each row's content
    let rowContent: (Item) -> RowContent
    /// View builder for bottom spacer/content
    let bottomContent: () -> BottomContent

    // MARK: - State

    @State private var hasAutoScrolled = false

    private var calendar: Calendar { Calendar.current }

    // MARK: - Initialization

    init(
        items: [Item],
        activeDate: Binding<Date>,
        scrollTarget: Binding<Date?>,
        dateForItem: @escaping (Item) -> Date,
        rowContent: @escaping (Item) -> RowContent,
        bottomContent: @escaping () -> BottomContent
    ) {
        self.items = items
        self._activeDate = activeDate
        self._scrollTarget = scrollTarget
        self.dateForItem = dateForItem
        self.rowContent = rowContent
        self.bottomContent = bottomContent
    }

    // MARK: - Content Generation

    @ViewBuilder
    private func content() -> some View {
        ForEach(items.indices, id: \.self) { index in
            let item = items[index]
            let dayDate = calendar.startOfDay(for: dateForItem(item))

            rowContent(item)
                .overlay(DayPositionTracker(date: dayDate))
                .id(dayDate)
                .padding()
            
            if index < items.count - 1 {
                Divider()
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    content()
                    bottomContent()
                }
            }
            .coordinateSpace(name: "scroll")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Lunar calendar days")
            .accessibilityHint("Swipe to navigate between days")
            .onChange(of: scrollTarget) { _, newTarget in
                guard let date = newTarget else { return }
                // scroll after layout has updated
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(date, anchor: .top)
                    }
                    // Clear the target once we've attempted the scroll.
                    scrollTarget = nil
                }
            }
            .onAppear {
                // Optional: if someone sets an initial scrollTarget before appearance
                if !hasAutoScrolled, let initial = scrollTarget {
                    DispatchQueue.main.async {
                        proxy.scrollTo(initial, anchor: .top)
                        hasAutoScrolled = true
                        scrollTarget = nil
                    }
                }
            }
        }
        .onPreferenceChange(DayPositionPreferenceKey.self) { values in
            // Choose the day whose row is closest to the top (but still visible)
            let sorted = values.sorted { lhs, rhs in
                abs(lhs.value) < abs(rhs.value)
            }
            if let first = sorted.first {
                activeDate = calendar.startOfDay(for: first.key)
            }
        }
    }
}

// MARK: - Convenience Extension for No Bottom Content

extension ScrollableDayList where BottomContent == EmptyView {
    init(
        items: [Item],
        activeDate: Binding<Date>,
        scrollTarget: Binding<Date?>,
        dateForItem: @escaping (Item) -> Date,
        rowContent: @escaping (Item) -> RowContent
    ) {
        self.items = items
        self._activeDate = activeDate
        self._scrollTarget = scrollTarget
        self.dateForItem = dateForItem
        self.rowContent = rowContent
        self.bottomContent = { EmptyView() }
    }
}

#Preview {
    @MainActor struct PreviewContainer: View {
        @State private var displayedMonth: Date = Date()
        @State private var activeDate: Date = Calendar.current.startOfDay(for: Date())
        @State private var scrollTarget: Date? = nil

        private var monthData: MonthData {
            MoonCalendarGenerator.buildMonthData(for: displayedMonth)
        }

        var body: some View {
            ScrollableDayList(
                items: monthData.monthCalendar.filter { !$0.isOverlap },
                activeDate: $activeDate,
                scrollTarget: $scrollTarget,
                dateForItem: { $0.date }
            ) { day in
                DayDetail(
                    date: day.date,
                    phase: day.phase,
                    displayMode: .full
                )
            }
        }
    }
    return PreviewContainer()
}
