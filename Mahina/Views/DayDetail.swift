import SwiftUI

struct DayDetail: View {
    enum DisplayMode {
        case full
        case smallWidget
        case mediumWidget
        case largeWidget
    }

    let date: Date
    let phase: MoonPhase?
    var displayMode: DisplayMode = .full
    var isAccentedRendering: Bool = false
    var showDescription: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: displayMode.isMediumWidget ? 8: 24) {
            if let phase {
                PhaseDetailHeader(
                    phase: phase,
                    displayMode: displayMode,
                    isAccentedRendering: isAccentedRendering
                )
                if showDescription {
                    PhaseDetailSection(
                        phase: phase,
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
    var isSmallWidget: Bool { self == .smallWidget }
    var isMediumWidget: Bool { self == .mediumWidget }
    var isLargeWidget: Bool { self == .largeWidget }
    var isFullApp: Bool { self == .full }
}

// MARK: - Header
private struct PhaseDetailHeader: View {
    let phase: MoonPhase
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

    private var isMacOS: Bool {
#if os(macOS)
        return true
#else
        return false
#endif
    }

    // MARK: - Body

    var body: some View {
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
        MoonImage(
            day: phase.day,
            isDetailed: !isAccentedRendering,
            isAccentedRendering: isAccentedRendering,
            accessibilityLabel: "Lunar day \(phase.day)",
            accessibilityValue: phase.name
        )
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
            Text(phase.name)
                .font(phaseTitleFont)
                .fontWeight(.semibold)
            Text(phase.description)
                .font(displayMode.isFullApp ? .body : .footnote)
                .fixedSize(horizontal: false, vertical: true)
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
        if displayMode.isFullApp {
            return isMacOS ? .title2 : .headline
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

    var body: some View {
        VStack(alignment: .leading, spacing: displayMode.isFullApp ? 16 : displayMode.isMediumWidget ? 0 : 8) {
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

    var body: some View {
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

    @ViewBuilder
    private var icon: some View {
        ZStack {
            if displayMode.isFullApp {
                Circle()
                    .fill(iconBackgroundMaterial)
                    .frame(width: 40, height: 40)

                Image(systemName: systemName.replacingOccurrences(of: ".circle.fill", with: ".fill"))
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: systemName)
                    .symbolRenderingMode(isAccentedRendering ? .monochrome : .palette)
                    .font(.system(size: 32))
                    .foregroundStyle(.primary, .thinMaterial)
            }
        }
        .frame(width: displayMode.isFullApp ? 64 : 36)
    }

    /*
     * Icon background material with platform-specific styling
     */
    private var iconBackgroundMaterial: AnyShapeStyle {
#if os(watchOS)
        return AnyShapeStyle(.primary.opacity(0.2))
#elseif os(macOS)
        return AnyShapeStyle(.primary.opacity(0.1))
#else
        return AnyShapeStyle(.thinMaterial)
#endif
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

#Preview {
    let today = Date()
    let phase = MoonCalendarGenerator.phase(for: today)
    return DayDetail(date: today, phase: phase)
}
