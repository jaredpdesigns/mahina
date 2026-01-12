import SwiftUI

/// Preference key for tracking scroll positions of day items in the list
public struct DayPositionPreferenceKey: PreferenceKey {
    nonisolated(unsafe) public static var defaultValue: [Date: CGFloat] = [:]

    public static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Invisible view that tracks and reports the vertical position of a day item in the scroll view
public struct DayPositionTracker: View {
    public let date: Date
    public let anchorPoint: UnitPoint

    public init(date: Date, anchorPoint: UnitPoint) {
        self.date = date
        self.anchorPoint = anchorPoint
    }

    public var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("scroll"))
            /*
             * Calculate position based on anchor point
             * UnitPoint(0.5, 0.5) = center, (0, 0) = top-left, etc.
             */
            let anchorY = frame.minY + (frame.height * anchorPoint.y)
            Color.clear.preference(
                key: DayPositionPreferenceKey.self,
                value: [date: anchorY]
            )
        }
    }
}

/// Generic scrollable list with automatic scrolling and active date tracking.
///
/// Provides a vertically scrollable list of items with automatic scroll-to-date functionality.
/// Tracks which day is currently at the activation threshold and updates the active date accordingly.
/// Includes position tracking for smooth programmatic scrolling to specific dates with configurable offset.
public struct ScrollableDayList<Item, RowContent: View, BottomContent: View>: View {
    // MARK: - Properties

    public let items: [Item]
@Binding public var activeDate: Date
@Binding public var scrollTarget: Date?

    /// Function to extract date from each item
    public let dateForItem: (Item) -> Date
    /// View builder for each row's content
    public let rowContent: (Item) -> RowContent
    /// View builder for bottom spacer/content
    public let bottomContent: () -> BottomContent

    /// Vertical position (in points from top) where an item becomes "active"
    /// Default: 100 points from top, which typically positions content nicely visible
    public var activationThreshold: CGFloat = 100

    /// Anchor point within each item to track (0 = top, 0.5 = center, 1 = bottom)
    public var trackingAnchor: UnitPoint = UnitPoint(x: 0.5, y: 0.2)

    public init(
        items: [Item],
        activeDate: Binding<Date>,
        scrollTarget: Binding<Date?>,
        dateForItem: @escaping (Item) -> Date,
        activationThreshold: CGFloat = 100,
        trackingAnchor: UnitPoint = UnitPoint(x: 0.5, y: 0.2),
        @ViewBuilder rowContent: @escaping (Item) -> RowContent,
        @ViewBuilder bottomContent: @escaping () -> BottomContent = { EmptyView() }
    ) {
        self.items = items
        self._activeDate = activeDate
        self._scrollTarget = scrollTarget
        self.dateForItem = dateForItem
        self.activationThreshold = activationThreshold
        self.trackingAnchor = trackingAnchor
        self.rowContent = rowContent
        self.bottomContent = bottomContent
    }

    // MARK: - State

@State public var hasAutoScrolled = false

    private var calendar: Calendar { Calendar.current }

    private var isWatchOS: Bool {
#if os(watchOS)
        return true
#else
        return false
#endif
    }

    // MARK: - Initialization

    public init(
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

            if isWatchOS {
                /*
                 * Simple card display for watchOS without heavy effects
                 */
                rowContent(item)
                    .overlay(DayPositionTracker(date: dayDate, anchorPoint: trackingAnchor))
                    .id(dayDate)
            } else {
                /*
                 * Carousel scroll transition effects for iOS/macOS
                 */
                rowContent(item)
                    .scrollTransition(.interactive, axis: .vertical) { content, phase in
                        content
                            .scaleEffect(
                                x: phase.isIdentity ? 1.0 : 0.95,
                                y: phase.isIdentity ? 1.0 : 0.95
                            )
                            .opacity(phase.isIdentity ? 1.0 : 0.6)
                            .blur(radius: phase.isIdentity ? 0 : 2)
                            .offset(y: phase.value * -20)
                    }
                    .overlay(DayPositionTracker(date: dayDate, anchorPoint: trackingAnchor))
                    .id(dayDate)
            }
        }
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: isWatchOS ? 16 : 24) {
                    content()
                    bottomContent()
                }
                .scrollTargetLayout()
                .padding(.vertical, isWatchOS ? 8 : 16)
            }
            .scrollTargetBehavior(.viewAligned)
            .coordinateSpace(name: "scroll")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Lunar calendar days")
            .accessibilityHint("Swipe to navigate between days")
            .onChange(of: scrollTarget) { _, newTarget in
                guard let date = newTarget else { return }
                /*
                 * scroll after layout has updated
                 */
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(date, anchor: .top)
                    }
                    /*
                     * Clear the target once we've attempted the scroll.
                     */
                    scrollTarget = nil
                }
            }
            .onAppear {
                /*
                 * Optional: if someone sets an initial scrollTarget before appearance
                 */
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
            /*
             * Find the item whose tracked anchor point is closest to our activation threshold.
             * Only consider items that have crossed the threshold (are past it moving down).
             */
            let candidates = values.filter { _, position in
                position >= 0 && position <= activationThreshold + 50
            }

            guard !candidates.isEmpty else { return }

            /*
             * Pick the one closest to our activation threshold
             */
            let sorted = candidates.sorted { lhs, rhs in
                abs(lhs.value - activationThreshold) < abs(rhs.value - activationThreshold)
            }

            if let best = sorted.first {
                let newActiveDate = calendar.startOfDay(for: best.key)
                if newActiveDate != activeDate {
                    activeDate = newActiveDate
                }
            }
        }
    }
}

// MARK: - Convenience Extension for No Bottom Content

public extension ScrollableDayList where BottomContent == EmptyView {
    public init(
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
                DayCard(
                    date: day.date,
                    phase: day.phase,
                    displayMode: .full
                )
            }
        }
    }
    return PreviewContainer()
}
