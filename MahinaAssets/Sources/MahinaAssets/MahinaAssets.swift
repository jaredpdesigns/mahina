/*
 * MahinaAssets
 * Public interface for shared Mahina models, views, and services
 */

import Foundation
import SwiftUI

// MARK: - Preview Helpers

/// Creates a Date from a string for use in SwiftUI previews.
/// - Parameter dateString: Date in "yyyy-MM-dd" format (e.g., "2025-02-27")
/// - Returns: The parsed Date, or current date if parsing fails
public func previewDate(_ dateString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: dateString) ?? Date()
}
