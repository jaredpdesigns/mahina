import SwiftUI

public struct DayDetail: View {
    public enum DisplayMode {
        case full
        case smallWidget
        case mediumWidget
        case largeWidget
    }
    
    public let date: Date
    public let phase: PhaseResult?
    public var displayMode: DisplayMode = .full
    public var isAccentedRendering: Bool = false
    public var showDescription: Bool = true
    /// When true and phase is a transition day, displays secondary phase info
    public var showSecondaryPhase: Bool = false
    
    public init(
        date: Date,
        phase: PhaseResult?,
        displayMode: DisplayMode = .full,
        isAccentedRendering: Bool = false,
        showDescription: Bool = true,
        showSecondaryPhase: Bool = false
    ) {
        self.date = date
        self.phase = phase
        self.displayMode = displayMode
        self.isAccentedRendering = isAccentedRendering
        self.showDescription = showDescription
        self.showSecondaryPhase = showSecondaryPhase
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: displayMode.isMediumWidget ? 8 : 24) {
            if let phase {
                PhaseDetailHeader(
                    phaseResult: phase,
                    displayMode: displayMode,
                    isAccentedRendering: isAccentedRendering
                )
                if showDescription {
                    PhaseDetailSection(
                        phase: phase.primary,
                        displayMode: displayMode,
                        isAccentedRendering: isAccentedRendering
                    )
                }
                /*
                 * Show secondary phase text info when enabled and this is a transition day
                 */
                if showSecondaryPhase, let secondary = phase.secondary {
                    SecondaryPhaseSection(
                        phase: secondary,
                        displayMode: displayMode,
                        isAccentedRendering: isAccentedRendering
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Display Mode Helpers
extension DayDetail.DisplayMode {
    public var isSmallWidget: Bool { self == .smallWidget }
    public var isMediumWidget: Bool { self == .mediumWidget }
    public var isLargeWidget: Bool { self == .largeWidget }
    public var isFullApp: Bool { self == .full }
}

// MARK: - Header
private struct PhaseDetailHeader: View {
    let phaseResult: PhaseResult
    let displayMode: DayDetail.DisplayMode
    let isAccentedRendering: Bool
    
    @State private var showTransitionExplanation = false
    
    private var phase: MoonPhase { phaseResult.primary }
    private var secondaryPhase: MoonPhase? { phaseResult.secondary }
    private var isTransitionDay: Bool { phaseResult.isTransitionDay }
    
    // MARK: - Platform Detection
    
    private var isWatchOS: Bool {
#if os(watchOS)
        return true
#else
        return false
#endif
    }
    
    private var isMacOS: Bool {
#if os(macOS)
        return true
#else
        return false
#endif
    }
    
    // MARK: - Body
    
    public var body: some View {
        headerContent
#if !os(watchOS)
            .popover(
                isPresented: $showTransitionExplanation,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .bottom
            ) {
                TransitionDayPopoverView()
                    .presentationCompactAdaptation(.popover)
            }
#endif
    }
    
    @ViewBuilder
    private var headerContent: some View {
        let content = headerLayout
        
#if os(watchOS)
        content
#else
        if isTransitionDay {
            Button(action: { showTransitionExplanation.toggle() }) {
                content
            }
            .buttonStyle(.plain)
            .accessibilityHint("Tap to learn about transition days")
        } else {
            content
        }
#endif
    }
    
    @ViewBuilder
    private var headerLayout: some View {
        if displayMode.isSmallWidget {
            VStack(alignment: .leading, spacing: 12) {
                headerImage
                headerText
            }
        } else {
            HStack(spacing: 16) {
                headerImage
                headerText
            }
        }
    }
    
    @ViewBuilder
    private var headerImage: some View {
        Group {
            if isTransitionDay, let secondary = secondaryPhase {
                SplitMoonImage(
                    primaryDay: phase.day,
                    secondaryDay: secondary.day,
                    isDetailed: !isAccentedRendering,
                    isAccentedRendering: isAccentedRendering
                )
                .accessibilityLabel("Transition day: \(phase.name) to \(secondary.name)")
            } else {
                MoonImage(
                    day: phase.day,
                    isDetailed: !isAccentedRendering,
                    isAccentedRendering: isAccentedRendering,
                    accessibilityLabel: "Lunar day \(phase.day)",
                    accessibilityValue: phase.name
                )
            }
        }
        .frame(width: imageSize, height: imageSize)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    private var imageSize: CGFloat {
        displayMode.isFullApp ? 64 : 40
    }
    
    private var shadowColor: Color {
        displayMode.isFullApp ? .black.opacity(0.125) : .clear
    }
    
    private var shadowRadius: CGFloat {
        displayMode.isFullApp ? 8 : 0
    }
    
    private var shadowOffset: CGFloat {
        displayMode.isFullApp ? 2 : 0
    }
    
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isTransitionDay, let secondary = secondaryPhase {
                /*
                 * Show both phase names for transition days with info icon
                 */
                HStack(spacing: 4) {
                    Text(phase.name)
                        .font(phaseTitleFont)
                        .fontWeight(.bold)
                    Text("→")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(secondary.name)
                        .font(phaseTitleFont)
                        .fontWeight(.bold)
#if !os(watchOS)
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
#endif
                }
                Text(phase.description)
                    .font(displayMode.isFullApp ? .body : .footnote)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(phase.name)
                    .font(phaseTitleFont)
                    .fontWeight(.semibold)
                Text(phase.description)
                    .font(displayMode.isFullApp ? .body : .footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moon phase: \(phase.name)")
        .accessibilityValue(phase.description)
    }
    
    /*
     * Phase title font: larger on macOS for menu bar visibility
     */
    private var phaseTitleFont: Font {
        if isMacOS || displayMode.isFullApp {
            return .largeTitle
        } else {
            return .title3
        }
    }
    
}

// MARK: - Section
private struct PhaseDetailSection: View {
    let phase: MoonPhase
    let displayMode: DayDetail.DisplayMode
    let isAccentedRendering: Bool
    
    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: displayMode.isFullApp ? 16 : displayMode.isMediumWidget ? 0 : 8
        ) {
            GuidanceItem(
                title: "Planting",
                content: phase.planting,
                systemName: "leaf.circle.fill",
                displayMode: displayMode,
                isAccentedRendering: isAccentedRendering
            )
            
            GuidanceItem(
                title: "Fishing",
                content: phase.fishing,
                systemName: "fish.circle.fill",
                displayMode: displayMode,
                isAccentedRendering: isAccentedRendering
            )
        }
    }
}

// MARK: - Secondary Phase Section
private struct SecondaryPhaseSection: View {
    let phase: MoonPhase
    let displayMode: DayDetail.DisplayMode
    let isAccentedRendering: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 12) {
                MoonImage(
                    day: phase.day,
                    isDetailed: !isAccentedRendering,
                    isAccentedRendering: isAccentedRendering,
                    accessibilityLabel: "Secondary lunar day \(phase.day)",
                    accessibilityValue: phase.name
                )
                .frame(width: 32, height: 32)
                .opacity(0.7)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Also: \(phase.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(phase.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .opacity(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Transition day also includes \(phase.name)")
    }
}

// MARK: - Guidance Item
private struct GuidanceItem: View {
    let title: String
    let content: String
    let systemName: String
    let displayMode: DayDetail.DisplayMode
    let isAccentedRendering: Bool
    
    // MARK: - Platform Detection
    
    private var isWatchOS: Bool {
#if os(watchOS)
        return true
#else
        return false
#endif
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if displayMode.isSmallWidget {
                VStack(alignment: .leading, spacing: 8) {
                    icon
                    text
                }
            } else {
                HStack(spacing: 16) {
                    icon
                    text
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) guidance")
        .accessibilityValue(content)
    }
    
    private var icon: some View {
        Image(systemName: systemName)
            .symbolRenderingMode(isAccentedRendering ? .monochrome : .palette)
            .font(.system(size: displayMode.isFullApp ? 48 : 40))
            .foregroundStyle(.primary, .thinMaterial)
            .frame(width: displayMode.isFullApp ? 64 : 40)
    }
    
    @ViewBuilder
    private var text: some View {
        VStack(alignment: .leading, spacing: 2) {
            if displayMode.isFullApp && !displayMode.isSmallWidget {
                Text(title)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
            }
            Text(content)
                .font(displayMode.isFullApp ? .body : .footnote)
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Transition Day Popover

/// Popover content explaining why two moons are displayed on transition days.
private struct TransitionDayPopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transition Day")
                .font(.headline)
            Text(
                "This day spans two lunar phases in the Hawaiian moon calendar. The overlapping moons show the transition from one phase to the next."
            )
        }
        .padding()
        .frame(width: 360, alignment: .leading)
    }
}

#Preview {
    let today = Date()
    let phaseResult = MoonCalendarGenerator.phase(for: today)
    return DayDetail(date: today, phase: phaseResult)
}
