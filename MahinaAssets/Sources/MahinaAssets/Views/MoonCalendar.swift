import SwiftUI

/// Interactive calendar grid view for date selection and month navigation.
///
/// Displays a traditional month grid with lunar phase indicators, supporting
/// both iOS and watchOS layouts. Highlights the currently selected date and
/// provides month navigation controls.
public struct MoonCalendar: View {
    // MARK: - Properties

    public let monthData: MonthData
    public var enablePopover: Bool = true
@Binding public var displayedMonth: Date
@Binding public var activeDate: Date

@State public var dragOffset: CGFloat = 0
@State public var showEnglishTranslation = false

    public init(monthData: MonthData, displayedMonth: Binding<Date>, activeDate: Binding<Date>, enablePopover: Bool = true) {
        self.monthData = monthData
        self._displayedMonth = displayedMonth
        self._activeDate = activeDate
        self.enablePopover = enablePopover
    }

    // MARK: - Platform Detection

    private var isWatchOS: Bool {
#if os(watchOS)
        return true
#else
        return false
#endif
    }

    /// Grid configuration for the 7-day week layout
    private let columns = Array(repeating: GridItem(.flexible(minimum: 24), spacing: 4), count: 7)

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: isWatchOS ? 4 : 8) {
            navigationHeader
            weekdayHeader
            calendarGrid
        }
        .gesture(swipeGesture)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Calendar for \(monthTitle)")
        .accessibilityHint("Swipe left for next month, swipe right for previous month, or use the navigation buttons")
        .accessibilityAction(named: "Previous Month") {
            shiftMonth(-1)
        }
        .accessibilityAction(named: "Next Month") {
            shiftMonth(1)
        }
    }

    // MARK: - Subviews

    /// Navigation header with previous/next buttons and month title
    private var navigationHeader: some View {
        HStack(spacing: 0) {
            Button(action: { shiftMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .frame(width: isWatchOS ? nil : 32, height: isWatchOS ? nil : 32)
                    .contentShape(Rectangle())
            }
            Spacer(minLength: 8)
            if enablePopover {
                Button(action: { showEnglishTranslation.toggle() }) {
                    monthTitleText
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Month header: \(monthTitle)")
                .accessibilityHint("Tap to view English translation")
            } else {
                monthTitleText
                    .accessibilityLabel("Month header: \(monthTitle)")
            }
            Spacer(minLength: 8)
            Button(action: { shiftMonth(1) }) {
                Image(systemName: "chevron.right")
                    .frame(width: isWatchOS ? nil : 32, height: isWatchOS ? nil : 32)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .animation(nil, value: displayedMonth)
        .padding(.horizontal, 8)
        .padding(.bottom, isWatchOS ? 0 : 8)
#if os(watchOS)
        .sheet(isPresented: $showEnglishTranslation) {
            if enablePopover {
                MonthTranslationPopoverView(englishMonth: fullEnglishMonth)
            }
        }
#else
        .popover(
            isPresented: $showEnglishTranslation,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top
        ) {
            if enablePopover {
                MonthTranslationPopoverView(englishMonth: fullEnglishMonth)
                    .presentationCompactAdaptation(.popover)
            }
        }
#endif
    }

    /// Weekday header row (S M T W T F S)
    private var weekdayHeader: some View {
        HStack {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                Text(d)
                    .font(isWatchOS ? .footnote : .caption)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Calendar grid of day cells
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: isWatchOS ? 0 : 4) {
            ForEach(monthData.monthCalendar) { day in
                dayCellButton(for: day)
            }
        }
    }

    /// Individual day cell button
    @ViewBuilder
    private func dayCellButton(for day: MoonDay) -> some View {
        Button {
            if !day.isOverlap { activeDate = day.date }
        } label: {
            dayCellContent(for: day)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!day.isOverlap)
    }

    /// Content for a day cell (number + moon image)
    @ViewBuilder
    private func dayCellContent(for day: MoonDay) -> some View {
        VStack(spacing: 4) {
            Text("\(day.calendarDay)")
                .font(isWatchOS ? .footnote : .caption)
                .frame(maxWidth: .infinity)
            ZStack(alignment: .topTrailing) {
                moonImage(for: day.day)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: moonImageSize, height: moonImageSize)
                    .opacity(day.isOverlap ? 0.5 : 1.0)
                if day.phase.isTransitionDay && !day.isOverlap {
                    transitionIndicator
                }
            }
        }
        .padding(.vertical, isWatchOS ? 2 : 4)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(dayCellBackground(for: day))
    }

    /// Background for a day cell (highlighted if selected)
    @ViewBuilder
    private func dayCellBackground(for day: MoonDay) -> some View {
        let isSelected = Calendar.current.isDate(day.date, inSameDayAs: activeDate)
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.primary.opacity(0.125) : Color.clear)
    }

    /// Transition day indicator dot
    private var transitionIndicator: some View {
        ZStack {
            Circle()
                .fill(transitionIndicatorBorderColor)
            Circle()
                .inset(by: 1)
                .fill(Color.gray)
        }
        .frame(width: 12, height: 12)
        .offset(x: 4, y: -4)
    }

    /// Swipe gesture for month navigation
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let swipeThreshold: CGFloat = 50
                if value.translation.width < -swipeThreshold {
                    /* Swiped left → next month */
                    shiftMonth(1)
                } else if value.translation.width > swipeThreshold {
                    /* Swiped right → previous month */
                    shiftMonth(-1)
                }
                dragOffset = 0
            }
    }

    // MARK: - Helper Properties

    /// Platform-specific moon image size
    private var moonImageSize: CGFloat {
        isWatchOS ? 20 : 24
    }

    /// Platform-specific system background color for transition indicator border
    private var transitionIndicatorBorderColor: Color {
#if os(watchOS)
        return Color.black
#elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
#else
        return Color(uiColor: .systemBackground)
#endif
    }

    /// Month title text view
    private var monthTitleText: some View {
        Text(monthTitle)
            .font(isWatchOS ? .body : .headline)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(minHeight: 32)
    }

    /// Formatted month/year title for the navigation header
    private var monthTitle: String {
        let year = Calendar.current.component(.year, from: displayedMonth)
        let monthName = HawaiianLocalization.month(for: displayedMonth) ?? englishMonth
        return "\(monthName) \(year)"
    }

    /// English month fallback
    private var englishMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = isWatchOS ? "LLL" : "LLLL"
        return formatter.string(from: displayedMonth)
    }

    /// Full English month and year for translation popover
    private var fullEnglishMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Actions

    /// Navigates to the previous or next month
    private func shiftMonth(_ months: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: months, to: displayedMonth) {
            var tx = Transaction()
            tx.disablesAnimations = true
            withTransaction(tx) {
                displayedMonth = newDate
            }
        }
    }
}

/// Popover content showing the English translation of the Hawaiian month.
private struct MonthTranslationPopoverView: View {
    let englishMonth: String

    public var body: some View {
        Text(englishMonth)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    @MainActor struct PreviewContainer: View {
        @State private var displayedMonth = Date()
        @State private var activeDate = Date()
        var body: some View {
            let monthData = MoonCalendarGenerator.buildMonthData(for: displayedMonth)
            return MoonCalendar(monthData: monthData, displayedMonth: $displayedMonth, activeDate: $activeDate)
                .padding()
        }
    }
    return PreviewContainer()
}
