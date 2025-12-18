import Foundation

/// Represents a single lunar phase with associated cultural and practical metadata.
///
/// Each phase corresponds to one of the 30 days in the Hawaiian lunar calendar system,
/// providing traditional guidance for planting and fishing activities.
struct MoonPhase: Identifiable, Hashable {
    /// A stable identifier for the phase.
    let id = UUID()
    /// The lunar day index (1...30).
    let day: Int
    /// The human‑readable name of the phase.
    let name: String
    /// A description of the phase.
    let description: String
    /// Planting guidance for this phase.
    let planting: String
    /// Fishing guidance for this phase.
    let fishing: String
    /// A grid position used for arranging phases in a matrix.
    let gridPosition: Int
    /// The name of the larger group this phase belongs to.
    let groupName: String
    /// A description of the larger group this phase belongs to.
    let groupDescription: String
}