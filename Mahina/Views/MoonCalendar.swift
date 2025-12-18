import SwiftUI
import Foundation

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
                Text(monthTitle)
                    .font(isWatchOS ? .body : .headline)
                    .fontWeight(.semibold)
                    .frame(minHeight: 32)
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
    }

    // MARK: - Helper Properties

    /// Platform-specific moon image size
    private var moonImageSize: CGFloat {
        isWatchOS ? 20 : 24
    }

    /// Formatted month/year title for the navigation header
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = isWatchOS ? "LLL yyy": "LLLL yyyy"
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
