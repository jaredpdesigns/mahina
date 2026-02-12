import SwiftUI

/// A card view that displays a single day's moon phase information.
///
/// Combines the DateHeader and DayDetail into a cohesive carousel card
/// with scroll transition effects. Each card represents one day in the lunar calendar.
public struct DayCard: View {
    public let date: Date
    public let phase: PhaseResult?
    public var displayMode: DayDetail.DisplayMode = .full
    
    public init(date: Date, phase: PhaseResult?, displayMode: DayDetail.DisplayMode = .full) {
        self.date = date
        self.phase = phase
        self.displayMode = displayMode
    }
    
    private var isWatchOS: Bool {
#if os(watchOS)
        return true
#else
        return false
#endif
    }
    
    private var cardBackgroundColor: Color {
#if os(watchOS)
        return Color(.darkGray).opacity(0.3)
#elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
#else  // iOS
        return Color(uiColor: .systemBackground)
#endif
    }
    
    private var cardPadding: CGFloat {
        isWatchOS ? 12 : 16
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: isWatchOS ? 12 : 16) {
            dateHeader
            Divider()
            phaseDetail
            if !isWatchOS {
                Spacer(minLength: 0)
            }
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: isWatchOS ? 12 : 24)
                .fill(cardBackgroundColor)
        )
        .padding(.horizontal, isWatchOS ? 4 : 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day card for \(date.formatted(date: .long, time: .omitted))")
        .accessibilityHint("Shows moon phase information including planting and fishing guidance")
        .accessibilityAddTraits(.isButton)
    }
    
    /*
     * Date header at the top of each card
     */
    @ViewBuilder
    private var dateHeader: some View {
        DateHeader(date: date, enablePopover: !isWatchOS, phase: phase)
    }
    
    /*
     * Phase details section - now uses DayDetail directly for all days
     * Transition days show split moon image within DayDetail
     */
    @ViewBuilder
    private var phaseDetail: some View {
        if let phase {
            DayDetail(
                date: date,
                phase: phase,
                displayMode: displayMode
            )
        }
    }
}

#Preview {
    let today = Date()
    let phaseResult = MoonCalendarGenerator.phase(for: today)
    return DayCard(date: today, phase: phaseResult)
}
