import Foundation

/// Represents a single lunar phase with associated cultural and practical metadata.
///
/// Each phase corresponds to one of the 30 days in the Hawaiian lunar calendar system,
/// providing traditional guidance for planting and fishing activities.
public struct MoonPhase: Identifiable, Hashable {
    /// A stable identifier for the phase.
    public let id = UUID()
    /// The lunar day index (1...30).
    public let day: Int
    /// The human‑readable name of the phase.
    public let name: String
    /// A description of the phase.
    public let description: String
    /// Planting guidance for this phase.
    public let planting: String
    /// Fishing guidance for this phase.
    public let fishing: String
    /// A grid position used for arranging phases in a matrix.
    public let gridPosition: Int
    /// The name of the larger group this phase belongs to.
    public let groupName: String
    /// A description of the larger group this phase belongs to.
    public let groupDescription: String
    
    public init(
        day: Int, name: String, description: String, planting: String, fishing: String,
        gridPosition: Int, groupName: String, groupDescription: String
    ) {
        self.day = day
        self.name = name
        self.description = description
        self.planting = planting
        self.fishing = fishing
        self.gridPosition = gridPosition
        self.groupName = groupName
        self.groupDescription = groupDescription
    }
}
