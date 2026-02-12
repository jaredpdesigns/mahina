import SwiftUI

/// Displays a formatted date header with Hawaiian weekday and date.
///
/// Shows the weekday in a secondary style above the full date in a large, bold format.
/// Used consistently across iOS, macOS, and watchOS for Hawaiian date display.
/// Tap to view the English translation in a popover (can be disabled).
public struct DateHeader: View {
    public let date: Date
    public var enablePopover: Bool = true
    public var isCompact: Bool = false
    /// Phase result for generating share content (iOS only)
    public var phase: PhaseResult? = nil
    
    public init(date: Date, enablePopover: Bool = true, isCompact: Bool = false, phase: PhaseResult? = nil) {
        self.date = date
        self.enablePopover = enablePopover
        self.isCompact = isCompact
        self.phase = phase
    }
    
    @State public var showEnglishTranslation = false
    
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
    
    private var fullEnglishDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
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
    
    public var body: some View {
        HStack {
            Group {
                if enablePopover {
                    Button(action: { showEnglishTranslation.toggle() }) {
                        dateContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Date header: \(weekdayString), \(dateString)")
                    .accessibilityHint("Tap to view English translation")
                } else {
                    dateContent
                        .accessibilityLabel("Date header: \(weekdayString), \(dateString)")
                }
            }
            
#if os(iOS)
            if let phase, !isCompact {
                let shareItem = PhaseShareContent.shareItem(for: phase, date: date)
                Spacer()
                ShareLink(
                    item: shareItem,
                    subject: Text(shareItem.subject),
                    message: Text(shareItem.text),
                    preview: SharePreview(
                        PhaseShareContent.previewTitle(for: phase, dateString: dateString),
                        image: PhaseShareContent.previewImage(for: phase)
                    )
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share moon phase")
                .accessibilityHint("Share this day's moon phase information")
            }
#endif
        }
#if os(watchOS)
        .sheet(isPresented: $showEnglishTranslation) {
            DateTranslationPopoverView(englishDate: fullEnglishDate)
        }
#else
        .popover(
            isPresented: $showEnglishTranslation,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .bottom
        ) {
            DateTranslationPopoverView(englishDate: fullEnglishDate)
                .presentationCompactAdaptation(.popover)
        }
#endif
    }
    
    private var dateContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(weekdayString)
                .font(isCompact ? .caption : nil)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Selected day: \(weekdayString)")
            Text(dateString)
                .font(isCompact ? .title2 : (isWatchOS ? .body : .title))
                .fontWeight(.bold)
        }
    }
}

/// Popover content showing the English translation of the Hawaiian date.
private struct DateTranslationPopoverView: View {
    let englishDate: String
    
    public var body: some View {
        Text(englishDate)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DateHeader(date: Date())
        .padding()
}
