import SwiftUI
import Foundation

/// Main view for the Mahina lunar calendar application.
///
/// Provides a scrollable interface showing detailed moon phase information for each day,
/// with navigation controls, phase group indicators, and calendar overlay functionality.
/// Manages the primary user experience for exploring the Hawaiian lunar calendar system.
struct ContentView: View {
    // MARK: - State Properties
    
    /// Date representing the month currently being displayed in the calendar
    @State private var displayedMonth: Date = Date()
    /// Currently selected/active date in the interface
    @State private var activeDate: Date = Date()
    /// Controls visibility of the month selection popover
    @State private var showCalendarPopover: Bool = false
    /// Target date for programmatic scrolling
    @State private var scrollTarget: Date? = nil
    /// Height of the top overlay for layout calculations
    @State private var topOverlayHeight: CGFloat = 100
    /// Controls initial loading state and animation
    @State private var isInitialLoading: Bool = true
    
    // MARK: - Computed Properties
    
    /// Formatted date string for navigation title display
    private var navigationTitleString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL d, yyyy"
        return formatter.string(from: activeDate)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter.string(from: activeDate)
    }
    
    /*
     * Derived month data
     */
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: displayedMonth, includeOverlap: false)
    }
    
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(activeDate)
    }
    
    private var groupRows: [MoonGroupRow] {
        MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: activeDate)
    }
    
    private var currentPhase: MoonPhase? {
        MoonCalendarGenerator.phase(for: activeDate)
    }
    
    private var mainScrollableList: some View {
        var scrollableList = ScrollableDayList(
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
            .padding(.vertical)
        } bottomContent: {
            Spacer()
                .frame(height: topOverlayHeight + 200)
        }
        
        /*
         * Use the actual top overlay height as the activation threshold
         * so items become "active" when they clear the header
         */
        scrollableList.activationThreshold = topOverlayHeight
        return scrollableList
    }
    
    private var topOverlayContent: some View {
        DateHeader(date: activeDate)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.bar)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            topOverlayHeight = geometry.size.height
                        }
                        .onChange(of: geometry.size.height) { _, newHeight in
                            topOverlayHeight = newHeight
                        }
                }
            )
    }
    
    private var bottomOverlayContent: some View {
        VStack {
            PhaseGroupsWithPopover(rows: groupRows)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                mainScrollableList
                    .safeAreaInset(edge: .top) {
                        topOverlayContent
                    }
                    .safeAreaInset(edge: .bottom) {
                        bottomOverlayContent
                    }
                    .onAppear {
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        displayedMonth = today
                        activeDate = today
                        scrollTarget = today
                    }
                
                // Show loading view during initial load
                if isInitialLoading {
                    
                    LoadingView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .toolbar { topToolbar() }
            .accessibilityLabel("Mahina Lunar Calendar")
            .accessibilityValue("Currently viewing \(navigationTitleString)")
            .onChange(of: scrollTarget) { _, _ in
                // Hide loading view after a delay when scroll target changes
                if isInitialLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isInitialLoading = false
                        }
                    }
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func topToolbar() -> some ToolbarContent {
        if !isInitialLoading {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    displayedMonth = today
                    activeDate = today
                    scrollTarget = today
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isToday ? "moon.fill" : "moon")
                        Text("Today")
                    }
                }
                .accessibilityLabel("Select today")
                .accessibilityHint("Change selected day to today")
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showCalendarPopover.toggle() }) {
                    Label("Calendar", systemImage: "calendar")
                }
                .accessibilityLabel("Open calendar")
                .accessibilityHint("Shows the month picker")
                .popover(
                    isPresented: $showCalendarPopover,
                    attachmentAnchor: .rect(.bounds),
                    arrowEdge: .top
                ) {
                    MoonCalendarOverlay(
                        initialMonth: displayedMonth,
                        initialActiveDate: activeDate
                    ) { selectedDate, monthAnchor in
                        let calendar = Calendar.current
                        let normalized = calendar.startOfDay(for: selectedDate)
                        displayedMonth = monthAnchor
                        activeDate = normalized
                        scrollTarget = normalized
                        showCalendarPopover = false
                    }
                    .frame(width: 360)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
    
    private func phaseFor(date: Date, in data: MonthData) -> MoonPhase? {
        data.monthBuilt.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.phase
    }
}


private struct LoadingView: View {
    let today = Date()
    
    private var currentPhase: MoonPhase {
        MoonCalendarGenerator.phase(for: today)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            MoonImage(
                day: currentPhase.day,
                isDetailed: true,
                accessibilityLabel: "Current moon phase",
                accessibilityValue: currentPhase.name
            )
            .frame(width: 64, height: 64)
            .scaleEffect(1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: currentPhase.day
            )
            
            DateHeader(date: today, enablePopover: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
