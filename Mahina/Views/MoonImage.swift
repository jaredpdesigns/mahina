import SwiftUI

/// A reusable moon image component that displays moon phase images with consistent styling.
/// Supports different visual variants and platform-specific adaptations.
struct MoonImage: View {
    enum Variant {
        case simple   // Current white/black appearance
        // case detailed // Future textured appearance
    }

    let day: Int
    var variant: Variant = .simple
    var isDetailed: Bool = false
    var isOverlap: Bool = false
    var isAccentedRendering: Bool = false
    var accessibilityLabel: String? = nil
    var accessibilityValue: String? = nil

    @Environment(\.colorScheme) private var colorScheme
    
    @ViewBuilder
    var img: some View {
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
    
    var body: some View {
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
