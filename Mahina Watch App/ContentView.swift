import SwiftUI
import MahinaAssets

/// Main interface for the Mahina lunar calendar Apple Watch application.
///
/// Displays a compact, scrollable carousel of lunar phase cards optimized for the watch interface.
/// Provides essential navigation and phase information with watchOS-appropriate sizing and interaction patterns.
struct ContentView: View {
    // MARK: - State Properties
    
    @State private var displayedMonth: Date = Date()
    @State private var activeDate: Date = Date()
    @State private var isShowingCalendarOverlay: Bool = false
    @State private var scrollTarget: Date? = nil
    @State private var hasAutoScrolledToToday: Bool = false
    
    // MARK: - Computed Properties
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: displayedMonth, includeOverlap: false)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(activeDate)
    }
    
    private var scrollableDayList: some View {
        var list = ScrollableDayList(
            items: monthData.monthCalendar,
            activeDate: $activeDate,
            scrollTarget: $scrollTarget,
            dateForItem: { $0.date }
        ) { day in
            /*
             * Use compact card design for watch
             */
            DayCard(
                date: day.date,
                phase: day.phase,
                displayMode: .smallWidget
            )
        }
        
        /*
         * Lower activation threshold for watch screen
         */
        list.activationThreshold = 50
        
        return list
    }
    
    var body: some View {
        NavigationStack {
            scrollableDayList
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            scrollToToday()
                        } label: {
                            Image(systemName: isToday ? "moon.fill" : "moon")
                                .font(.title3)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingCalendarOverlay = true
                        } label: {
                            Image(systemName: "calendar")
                                .font(.title3)
                        }
                    }
                }
                .onAppear {
                    if !hasAutoScrolledToToday {
                        scrollToToday()
                        hasAutoScrolledToToday = true
                    }
                }
                .onOpenURL { url in
                    if url.host == "today" {
                        scrollToToday()
                    }
                }
        }
        .sheet(isPresented: $isShowingCalendarOverlay) {
            ScrollView {
                MoonCalendarOverlay(
                    initialMonth: displayedMonth,
                    initialActiveDate: activeDate,
                    enablePopover: false
                ) { selectedDate, monthAnchor in
                    let calendar = Calendar.current
                    let normalized = calendar.startOfDay(for: selectedDate)
                    
                    displayedMonth = monthAnchor
                    activeDate = normalized
                    isShowingCalendarOverlay = false
                    scrollTarget = normalized
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func scrollToToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        /*
         * Anchor the displayed month to the month that contains today.
         */
        if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) {
            displayedMonth = monthStart
        } else {
            displayedMonth = today
        }
        
        /*
         * Make today the active date and schedule a scroll to that day.
         */
        activeDate = today
        scrollTarget = today
    }
}

#Preview {
    ContentView()
}
