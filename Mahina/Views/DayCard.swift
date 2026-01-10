import SwiftUI

/// A card view that displays a single day's moon phase information.
///
/// Combines the DateHeader and DayDetail into a cohesive carousel card
/// with scroll transition effects. Each card represents one day in the lunar calendar.
struct DayCard: View {
    let date: Date
    let phase: MoonPhase?
    var displayMode: DayDetail.DisplayMode = .full

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
#else
        return Color(uiColor: .systemBackground)
#endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isWatchOS ? 12 : 24) {
            /*
             * Date header at the top of each card
             */
            DateHeader(date: date, enablePopover: !isWatchOS)
                .padding(.horizontal, isWatchOS ? 12 : 16)
                .padding(.top, isWatchOS ? 12 : 16)

            /*
             * Phase details in the middle
             */
            if let phase {
                DayDetail(
                    date: date,
                    phase: phase,
                    displayMode: displayMode
                )
                .padding(.horizontal, isWatchOS ? 12 : 16)
                .padding(.bottom, isWatchOS ? 12 : 0)
            }

            if !isWatchOS {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isWatchOS ? 12 : 24)
                .fill(cardBackgroundColor)
        )
        .padding(.horizontal, isWatchOS ? 4 : 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Day card for \(date.formatted(date: .long, time: .omitted))")
    }
}

#Preview {
    let today = Date()
    let phase = MoonCalendarGenerator.phase(for: today)
    return DayCard(date: today, phase: phase)
}
