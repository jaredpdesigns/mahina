import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

/// A shareable moon phase item that conforms to Transferable.
///
/// By explicitly declaring transfer representations, the system knows
/// this is plain text content and surfaces appropriate actions like
/// Copy, Messages, Mail, etc.
public struct MoonPhaseShareItem: Transferable {
    public let text: String
    public let subject: String
    
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { item in
            item.text
        }
    }
}

/// Generates shareable content for a moon phase
public struct PhaseShareContent {
    /// Creates a fully configured share item for a given phase and date
    public static func shareItem(for phase: PhaseResult, date: Date) -> MoonPhaseShareItem {
        let dateString = hawaiianDateString(for: date)
        let phaseName: String
        
        if phase.isTransitionDay, let secondary = phase.secondary {
            phaseName = "\(phase.primary.name)→\(secondary.name)"
        } else {
            phaseName = phase.primary.name
        }
        
        let text = """
        🌙 \(phaseName): \(dateString)
        
        🍃 \(phase.primary.planting)
        
        🐟 \(phase.primary.fishing)
        """
        
        return MoonPhaseShareItem(
            text: text,
            subject: "🌙 \(phaseName): \(dateString)"
        )
    }
    
    /// Returns the moon phase image from the asset catalog for use in share previews
    public static func previewImage(for phase: PhaseResult) -> Image {
        Image("moon-detailed-\(phase.primary.day)", bundle: .module)
            .renderingMode(.original)
    }
    
    /// Builds the share preview title with the moon emoji prefix
    public static func previewTitle(for phase: PhaseResult, dateString: String) -> String {
        if phase.isTransitionDay, let secondary = phase.secondary {
            return "\(phase.primary.name)→\(secondary.name): \(dateString)"
        }
        return "\(phase.primary.name): \(dateString)"
    }
    
    private static func hawaiianDateString(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        let month = HawaiianLocalization.month(for: date) ?? {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = "LLLL"
            return formatter.string(from: date)
        }()
        return "\(month) \(day), \(year)"
    }
}
