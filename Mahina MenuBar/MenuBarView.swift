import SwiftUI
import AppKit
import MahinaAssets

struct MenuBarView: View {
    @Bindable var moonController: MoonController
    @State private var showCalendarPopover: Bool = false
    
    // MARK: - Computed Properties
    
    private var monthData: MonthData {
        MoonCalendarGenerator.buildMonthData(for: moonController.displayedMonth, includeOverlap: false)
    }
    
    private var groupRows: [MoonGroupRow] {
        MoonCalendarGenerator.buildGroupRows(monthData: monthData, activeDate: moonController.activeDate)
    }
    
    private var currentPhase: PhaseResult? {
        MoonCalendarGenerator.phase(for: moonController.activeDate)
    }
    
    // MARK: - Actions
    
    private func shiftDay(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: moonController.activeDate) {
            moonController.updatePhase(for: newDate)
        }
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
                            
                            Button(action: { moonController.goToToday() }) {
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
                                initialMonth: moonController.displayedMonth,
                                initialActiveDate: moonController.activeDate
                            ) { selectedDate, monthAnchor in
                                moonController.displayedMonth = monthAnchor
                                moonController.updatePhase(for: selectedDate)
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
                    .padding(.horizontal, 12)
                    .frame(height: 24)
                    .background(
                        Capsule()
                            .fill(.quaternary)
                    )
                }.padding(12)
                Divider()
                DateHeader(date: moonController.activeDate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                Divider()
                DayDetail(
                    date: moonController.activeDate,
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
