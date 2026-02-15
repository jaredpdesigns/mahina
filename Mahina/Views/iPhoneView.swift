import SwiftUI
import MahinaAssets

/// iPhone layout for Mahina
///
/// Scrollable day card carousel with floating phase groups overlay,
/// toolbar with Today button and calendar popover.
struct iPhoneView: View {
    @Binding var displayedMonth: Date
    @Binding var activeDate: Date
    @Binding var scrollTarget: Date?
    @Binding var isInitialLoading: Bool
    @State private var showCalendarPopover: Bool = false
    
    // MARK: - Computed Properties
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: displayedMonth, includeOverlap: false)
    }
    
    private var groupRows: [MoonGroupRow] {
        MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: activeDate)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.secondarySystemBackground)
                    .ignoresSafeArea()
                
                mainScrollableList
                    .onAppear {
                        /*
                         * Only set default values if still in initial loading state.
                         * A deep link may have already set the target date and
                         * dismissed loading before onAppear fires.
                         */
                        guard isInitialLoading else { return }
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        displayedMonth = today
                        activeDate = today
                        scrollTarget = today
                    }
                
                /* Floating pill-shaped phase groups indicator */
                bottomOverlayContent
                
                if isInitialLoading {
                    LoadingView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .toolbar { topToolbar() }
            .accessibilityLabel("Mahina Lunar Calendar")
            .onChange(of: scrollTarget) { _, _ in
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
    
    // MARK: - Subviews
    
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
            .transition(.opacity.combined(with: .scale))
        } bottomContent: {
            /*
             * Bottom spacer to prevent last card from being covered by floating overlay
             * Height accounts for pill height (~80pt) + padding (32pt) + safe area (34pt)
             */
            Spacer()
                .frame(height: 150)
        }
        
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
    
    // MARK: - Toolbar
    
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
                    HapticManager.light()
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
                        HapticManager.success()
                    }
                    .frame(width: 360)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
}
