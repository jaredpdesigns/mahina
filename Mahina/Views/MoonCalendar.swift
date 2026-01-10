import SwiftUI

/// Interactive calendar grid view for date selection and month navigation.
///
/// Displays a traditional month grid with lunar phase indicators, supporting
/// both iOS and watchOS layouts. Highlights the currently selected date and
/// provides month navigation controls.
struct MoonCalendar: View {
    // MARK: - Properties

    let monthData: MonthData
    @Binding var displayedMonth: Date
    @Binding var activeDate: Date

    @State private var dragOffset: CGFloat = 0
    @State private var showEnglishTranslation = false

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

    var body: some View {
        VStack(alignment: .leading, spacing: isWatchOS ? 4 : 8) {
            HStack(spacing: 0) {
                Button(action: { shiftMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .frame(width: isWatchOS ? nil : 32, height: isWatchOS ? nil : 32)
                        .contentShape(Rectangle())
                }
                Spacer(minLength: 8)
                Button(action: { showEnglishTranslation.toggle() }) {
                    Text(monthTitle)
                        .font(isWatchOS ? .body : .headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(minHeight: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Month header: \(monthTitle)")
                .accessibilityHint("Tap to view English translation")
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
            .padding(.bottom, isWatchOS ? 0:8)
#if os(watchOS)
            .sheet(isPresented: $showEnglishTranslation) {
                MonthTranslationPopoverView(englishMonth: fullEnglishMonth)
            }
#else
            .popover(
                isPresented: $showEnglishTranslation,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                MonthTranslationPopoverView(englishMonth: fullEnglishMonth)
                    .presentationCompactAdaptation(.popover)
            }
#endif
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                    Text(d)
                        .font(isWatchOS ? .footnote : .caption)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: isWatchOS ? 0 : 4) {
                ForEach(monthData.monthCalendar) { day in
                    Button {
                        if !day.isOverlap { activeDate = day.date }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(day.calendarDay)")
                                .font(isWatchOS ? .footnote : .caption)
                                .frame(maxWidth: .infinity)
                            MoonImage(
                                day: day.day,
                                isOverlap: day.isOverlap
                            )
                            .frame(width: moonImageSize, height: moonImageSize)
                            .shadow(
                                color: day.isOverlap ? Color.clear : Color.black.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 1
                            )
                        }
                        .padding(.vertical, isWatchOS ? 2 : 4)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    Calendar.current.isDate(day.date, inSameDayAs: activeDate)
                                    ? Color.primary.opacity(0.125)
                                    : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(!day.isOverlap)
                }
            }
        }
        .gesture(
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
        )
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

    // MARK: - Helper Properties

    /// Platform-specific moon image size
    private var moonImageSize: CGFloat {
        isWatchOS ? 20 : 24
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

    var body: some View {
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
