import SwiftUI

/// Displays a formatted date header with Hawaiian weekday and date.
///
/// Shows the weekday in a secondary style above the full date in a large, bold format.
/// Used consistently across iOS, macOS, and watchOS for Hawaiian date display.
struct DateHeader: View {
    let date: Date
    
    // MARK: - Computed Properties
    
    private var weekdayString: String {
        HawaiianLocalization.weekday(for: date) ?? englishWeekday
    }
    
    private var dateString: String {
        let day = Calendar.current.component(.day, from: date)
        let year = Calendar.current.component(.year, from: date)
        let month = HawaiianLocalization.month(for: date) ?? englishMonth
        return "\(month) \(day), \(year)"
    }
    
    // MARK: - English Fallbacks
    
    private var englishWeekday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var englishMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date)
    }
    
    private var isWatchOS: Bool {
#if os(watchOS)
        return true
#else
        return false
#endif
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(weekdayString)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Selected day: \(weekdayString)")
            Text(dateString)
                .font(isWatchOS ? .body : .largeTitle)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    DateHeader(date: Date())
        .padding()
}

