import SwiftUI
import MahinaAssets

/// iPad layout for Mahina
///
/// NavigationSplitView with:
/// - Sidebar: Today button, calendar grid, phase groups
/// - Primary: Same scrollable day card list as iPhone
struct iPadView: View {
    @Binding var displayedMonth: Date
    @Binding var activeDate: Date
    @Binding var scrollTarget: Date?
    
    // MARK: - Computed Properties
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: displayedMonth, includeOverlap: false)
    }
    
    private var groupRows: [MoonGroupRow] {
        MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: activeDate)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Divider()
                    .padding(.vertical, -8)
                
                MoonCalendarOverlay(
                    initialMonth: displayedMonth,
                    initialActiveDate: activeDate
                ) { selectedDate, monthAnchor in
                    let calendar = Calendar.current
                    let normalized = calendar.startOfDay(for: selectedDate)
                    displayedMonth = monthAnchor
                    activeDate = normalized
                    scrollTarget = normalized
                    HapticManager.selection()
                }
                .padding(.vertical, -8)
                
                Spacer()
            }
            .navigationTitle("Select a Date")
        } detail: {
            ZStack(alignment: .bottom) {
                Color(.secondarySystemBackground)
                    .ignoresSafeArea()
                
                mainScrollableList
                
                /* Floating phase groups at bottom */
                PhaseGroupsWithPopover(rows: groupRows)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.bar)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
                    )
                    .padding(.horizontal)
            }.toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
            }
        }
        .onAppear {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            displayedMonth = today
            activeDate = today
            scrollTarget = today
        }
    }
    
    // MARK: - Subviews
    
    private var mainScrollableList: some View {
        ScrollableDayList(
            items: monthData.monthCalendar.filter { !$0.isOverlap },
            activeDate: $activeDate,
            scrollTarget: $scrollTarget,
            dateForItem: { $0.date },
            activationThreshold: 200,
            rowContent: { day in
                DayCard(
                    date: day.date,
                    phase: day.phase,
                    displayMode: .full
                )
                .transition(.opacity.combined(with: .scale))
            },
            bottomContent: {
                /* Extra space so last card isn't hidden behind floating phase groups */
                Spacer()
                    .frame(height: 100)
            }
        )
    }
}
