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
            Image("moon-detailed-\(day)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
        } else {
            Image("moon-\(day)")
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

// MARK: - Preview

#Preview {
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
