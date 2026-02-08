import SwiftUI
import MahinaAssets

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
    /// Controls initial loading state and animation
    @State private var isInitialLoading: Bool = true
    
    // MARK: - Computed Properties
    
    /*
     * Derived month data
     */
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: displayedMonth, includeOverlap: false)
    }
    
    
    private var groupRows: [MoonGroupRow] {
        MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: activeDate)
    }
    
    private var mainScrollableList: some View {
        var scrollableList = ScrollableDayList(
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
        } bottomContent: {
            /*
             * Bottom spacer to prevent last card from being covered by floating overlay
             * Height accounts for pill height (~80pt) + padding (32pt) + safe area (34pt)
             */
            Spacer()
                .frame(height: 150)
        }
        
        /*
         * Use a card-friendly activation threshold (center of screen)
         */
        scrollableList.activationThreshold = 200
        return scrollableList
    }
    
    private var bottomOverlayContent: some View {
        PhaseGroupsWithPopover(rows: groupRows)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.bar)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            )
            .padding(.horizontal)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                /*
                 * Background color for the carousel
                 */
                Color(.secondarySystemBackground)
                    .ignoresSafeArea()
                
                /*
                 * Main scrollable card list
                 */
                mainScrollableList
                    .onAppear {
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        displayedMonth = today
                        activeDate = today
                        scrollTarget = today
                    }
                
                /*
                 * Floating pill-shaped phase groups indicator at bottom
                 */
                bottomOverlayContent
                
                /*
                 * Show loading view during initial load
                 */
                if isInitialLoading {
                    LoadingView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .toolbar { topToolbar() }
            .accessibilityLabel("Mahina Lunar Calendar")
            .onChange(of: scrollTarget) { _, _ in
                /*
                 * Hide loading view after a delay when scroll target changes
                 */
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
                        let isToday = Calendar.current.isDateInToday(activeDate)
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
}


private struct LoadingView: View {
    let today = Date()
    
    private var currentPhase: MoonPhase {
        MoonCalendarGenerator.phase(for: today).primary
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
            
            Text(currentPhase.name)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
