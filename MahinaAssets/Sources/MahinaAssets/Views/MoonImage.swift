import SwiftUI

/// A reusable moon image component that displays moon phase images with consistent styling.
/// Supports different visual variants and platform-specific adaptations.
public struct MoonImage: View {
    public enum Variant {
        case simple   // Current white/black appearance
        // case detailed // Future textured appearance
    }

    public let day: Int
    public var variant: Variant = .simple
    public var isDetailed: Bool = false
    public var isOverlap: Bool = false
    public var isAccentedRendering: Bool = false
    public var accessibilityLabel: String? = nil
    public var accessibilityValue: String? = nil

    public init(day: Int, variant: Variant = .simple, isDetailed: Bool = false, isOverlap: Bool = false, isAccentedRendering: Bool = false, accessibilityLabel: String? = nil, accessibilityValue: String? = nil) {
        self.day = day
        self.variant = variant
        self.isDetailed = isDetailed
        self.isOverlap = isOverlap
        self.isAccentedRendering = isAccentedRendering
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
    }

    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    public var img: some View {
        if isDetailed {
            Image("moon-detailed-\(day)", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
        } else {
            Image("moon-\(day)", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(moonForegroundColor)
                .background(
                    Group {
                        if !isAccentedRendering {
                            Circle()
                                .inset(by: 2)
                                .fill(.thinMaterial)
                        }
                    }
                )
                .opacity(isOverlap ? 0.5 : 1.0)
        }
    }

    public var body: some View {
        img
            .if(accessibilityLabel != nil) { view in
                view.accessibilityLabel(accessibilityLabel!)
            }
            .if(accessibilityValue != nil) { view in
                view.accessibilityValue(accessibilityValue!)
            }
    }

    // MARK: - Computed Properties

    private var moonForegroundColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        default:
            return .black
        }
    }
}

// MARK: - View Extension for Conditional Modifiers

private extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Split Moon Image for Transition Days

/// An overlapping moon image showing two phases.
/// Used on transition days to show both the ending and beginning phases.
/// Primary phase in top-left, secondary phase in bottom-right (overlapping).
public struct SplitMoonImage: View {
    public let primaryDay: Int
    public let secondaryDay: Int
    public var isDetailed: Bool = false

    public init(primaryDay: Int, secondaryDay: Int, isDetailed: Bool = false, dividerColor: Color = .clear) {
        self.primaryDay = primaryDay
        self.secondaryDay = secondaryDay
        self.isDetailed = isDetailed
    }

    public var body: some View {
        GeometryReader { geometry in
            let totalSize = min(geometry.size.width, geometry.size.height)
            /*
             * Each moon is 75% of total frame (48px when frame is 64px)
             */
            let moonSize = totalSize * 0.75
            /*
             * Offset to position in corners
             */
            let offset = totalSize - moonSize

            ZStack(alignment: .topLeading) {
                /*
                 * Primary phase - top-left corner (bottom layer)
                 */
                MoonImage(day: primaryDay, isDetailed: isDetailed)
                    .frame(width: moonSize, height: moonSize)

                /*
                 * Secondary phase - bottom-right corner (top layer)
                 */
                MoonImage(day: secondaryDay, isDetailed: isDetailed)
                    .frame(width: moonSize, height: moonSize)
                    .offset(x: offset, y: offset)
            }
            .frame(width: totalSize, height: totalSize)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Preview

#Preview("Split Moon") {
    VStack(spacing: 20) {
        HStack(spacing: 32) {
            VStack {
                SplitMoonImage(
                    primaryDay: 30,
                    secondaryDay: 1
                )
                .frame(width: 64, height: 64)
                Text("Muku → Hilo")
                    .font(.caption)
            }

            VStack {
                SplitMoonImage(
                    primaryDay: 13,
                    secondaryDay: 14
                )
                .frame(width: 64, height: 64)
                Text("Māhealani → Akua")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.black)

        Text("Top-left = primary, Bottom-right = secondary (overlapping)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("Moon Image") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            MoonImage(
                day: 15,
                isDetailed: true,
                accessibilityLabel: "Lunar day 15",
                accessibilityValue: "Full Moon"

            )
            .frame(width: 64, height: 64)

            MoonImage(
                day: 15,
                accessibilityLabel: "Lunar day 15",
                accessibilityValue: "Full Moon"
            )
            .frame(width: 40, height: 40)
        }

        Text("Different moon image sizes")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
