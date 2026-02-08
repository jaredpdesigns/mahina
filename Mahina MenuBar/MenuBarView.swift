import SwiftUI
import AppKit
import MahinaAssets

struct MenuBarView: View {
    @ObservedObject var moonController: MoonController
    @State private var displayedMonth: Date = Date()
    @State private var activeDate: Date = Date()
    @State private var showCalendarPopover: Bool = false
    
    // MARK: - Computed Properties
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: displayedMonth, includeOverlap: false)
    }
    
    private var groupRows: [MoonGroupRow] {
        MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: activeDate)
    }
    
    private var currentPhase: PhaseResult? {
        MoonCalendarGenerator.phase(for: activeDate)
    }
    
    // MARK: - Actions
    
    /*
     * Navigates to the previous or next day
     */
    private func shiftDay(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: activeDate) {
            activeDate = Calendar.current.startOfDay(for: newDate)
            /*
             * Update displayed month if we cross month boundary
             */
            if !Calendar.current.isDate(newDate, equalTo: displayedMonth, toGranularity: .month) {
                displayedMonth = newDate
            }
            /*
             * Update menu bar icon to reflect the new date's phase
             */
            moonController.updatePhase(for: newDate)
        }
    }
    
    /*
     * Returns to today's date
     */
    private func goToToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        displayedMonth = today
        activeDate = today
        /*
         * Update menu bar icon to today's phase
         */
        moonController.updatePhase(for: today)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let phase = currentPhase {
                HStack() {
                    HStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Button(action: { shiftDay(-1) }) {
                                Image(systemName: "chevron.left")
                                    .frame(width: 24, height: 24)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .background(
                                Capsule()
                                    .fill(.quaternary)
                            )
                            .accessibilityLabel("Previous day")
                            
                            Button(action: { goToToday() }) {
                                HStack(spacing: 4) {
                                    Text("Today")
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 24)
                            }
                            .buttonStyle(.borderless)
                            .background(
                                Capsule()
                                    .fill(.quaternary)
                            )
                            .accessibilityLabel("Go to today")
                            .accessibilityHint("Returns to today's date")
                            
                            Button(action: { shiftDay(1) }) {
                                Image(systemName: "chevron.right")
                                    .frame(width: 24, height: 24)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .background(
                                Capsule()
                                    .fill(.quaternary)
                            )
                            .accessibilityLabel("Next day")
                        }
                        Button(action: { showCalendarPopover.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("Calendar")
                            }
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 12)
                        .frame(height: 24)
                        .background(
                            Capsule()
                                .fill(.quaternary)
                        )
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
                                showCalendarPopover = false
                                /*
                                 * Update menu bar icon to reflect the selected date's phase
                                 */
                                moonController.updatePhase(for: normalized)
                            }
                            .frame(width: 360)
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                    Spacer()
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Quit")
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 12)
                    .frame(height: 24)
                    .background(
                        Capsule()
                            .fill(.quaternary)
                    )
                }.padding(12)
                Divider()
                DateHeader(date: activeDate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                Divider()
                DayDetail(
                    date: activeDate,
                    phase: phase,
                    displayMode: .full
                ).padding()
                Divider()
                PhaseGroupsWithPopover(rows: groupRows)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .padding(.bottom, 4)
            }
        }
        .frame(width: 400)
    }
}
