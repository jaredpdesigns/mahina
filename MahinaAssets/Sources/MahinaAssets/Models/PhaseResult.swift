import Foundation

/// Result of a phase lookup that may include transition day information.
///
/// For most days, only `primary` is populated. For transition days (where the
/// calendar day falls near a lunar phase boundary), `secondary` contains the
/// adjacent phase that also applies to this day.
public struct PhaseResult: Hashable {
    /// The primary phase for this date (used for navigation and fill state)
    public let primary: MoonPhase
    
    /// The adjacent phase when this is a transition day; nil otherwise
    public let secondary: MoonPhase?
    
    /// Convenience: true when this day spans two phases
    public var isTransitionDay: Bool { secondary != nil }
    
    public init(primary: MoonPhase, secondary: MoonPhase? = nil) {
        self.primary = primary
        self.secondary = secondary
    }
}
