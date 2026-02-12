import SwiftUI

#if os(iOS)
import UIKit

/// Haptic feedback manager for iOS
public struct HapticManager {
    /// Provides light haptic feedback
    public static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Provides medium haptic feedback
    public static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Provides selection change haptic feedback
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Provides success haptic feedback
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#elseif os(watchOS)
import WatchKit

/// Haptic feedback manager for watchOS
public struct HapticManager {
    /// Provides light haptic feedback
    public static func light() {
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Provides medium haptic feedback
    public static func medium() {
        WKInterfaceDevice.current().play(.directionUp)
    }
    
    /// Provides selection change haptic feedback
    public static func selection() {
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Provides success haptic feedback
    public static func success() {
        WKInterfaceDevice.current().play(.success)
    }
}

#else

/// Haptic feedback manager stub for macOS
public struct HapticManager {
    public static func light() {}
    public static func medium() {}
    public static func selection() {}
    public static func success() {}
}

#endif
