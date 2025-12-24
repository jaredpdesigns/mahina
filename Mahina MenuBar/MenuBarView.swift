import SwiftUI
import Foundation
import AppKit

struct MenuBarView: View {
    @ObservedObject var moonController: MoonController
    @Environment(\.colorScheme) private var colorScheme
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
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(activeDate)
    }
    
    private var currentPhase: MoonPhase? {
        MoonCalendarGenerator.phase(for: activeDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let phase = currentPhase {
                HStack() {
                    HStack(spacing: 16) {
                        Button(action: {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())
                            displayedMonth = today
                            activeDate = today
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isToday ? "moon.fill" : "moon")
                                Text("Today")
                            }
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Select today")
                        .accessibilityHint("Change selected day to today")
                        Button(action: { showCalendarPopover.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("Calendar")
                            }
                        }
                        .buttonStyle(.borderless)
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
                }.padding()
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
            }
        }
        .frame(width: 400)
    }
}
