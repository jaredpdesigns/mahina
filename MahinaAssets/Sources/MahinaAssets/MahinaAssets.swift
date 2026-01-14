/*
 * MahinaAssets
 * Public interface for shared Mahina models, views, and services
 */

import Foundation
import SwiftUI

// MARK: - Image Helpers

/// Returns a moon phase image from the MahinaAssets bundle.
///
/// Use this when you need direct access to the Image (e.g., for template rendering in complications).
/// For most view contexts, prefer using `MoonImage` view component instead.
///
/// - Parameters:
///   - day: The lunar day (1-30)
///   - isDetailed: Image variant selection:
///     - `false` (default): Simple outlined variant - works with `.renderingMode(.template)`
///       for system theming. Use for: menu bar, watch complications, calendar grids, accented widgets.
///     - `true`: Detailed textured variant - realistic appearance for full-color displays.
///       Use for: main app large display, DayCard, full-color widgets.
/// - Returns: The SwiftUI Image for the specified moon phase
public func moonImage(for day: Int, isDetailed: Bool = false) -> Image {
    let name = isDetailed ? "moon-detailed-\(day)" : "moon-\(day)"
    return Image(name, bundle: .module)
}

// MARK: - Preview Helpers

/// Creates a Date from a string for use in SwiftUI previews.
/// - Parameter dateString: Date in "yyyy-MM-dd" format (e.g., "2025-02-27")
/// - Returns: The parsed Date, or current date if parsing fails
public func dateFromString(_ dateString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString) ?? Date()
}
