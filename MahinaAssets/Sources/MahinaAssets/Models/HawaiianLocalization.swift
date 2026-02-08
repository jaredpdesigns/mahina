import Foundation

/// Hawaiian language translations for calendar elements.
///
/// Provides Hawaiian translations for weekdays, months, and other calendar-related terms
/// used throughout the Mahina application.
public struct HawaiianLocalization {
    
    // MARK: - Weekdays
    
    /// Hawaiian names for days of the week (1 = Sunday, 7 = Saturday)
    public static let weekdays: [Int: String] = [
        1: "Lāpule",  // Sunday
        2: "Pōʻakahi",  // Monday
        3: "Pōʻalua",  // Tuesday
        4: "Pōʻakolu",  // Wednesday
        5: "Pōʻahā",  // Thursday
        6: "Pōʻalima",  // Friday
        7: "Pōʻaono",  // Saturday
    ]
    
    // MARK: - Months
    
    /// Hawaiian names for months (1 = January, 12 = December)
    public static let months: [Int: String] = [
        1: "Ianuali",  // January
        2: "Pepeluali",  // February
        3: "Malaki",  // March
        4: "ʻApelila",  // April
        5: "Mei",  // May
        6: "Iune",  // June
        7: "Iulai",  // July
        8: "ʻAukake",  // August
        9: "Kepakemapa",  // September
        10: "ʻOkakopa",  // October
        11: "Nowemapa",  // November
        12: "Kekemapa",  // December
    ]
    
    // MARK: - Helper Methods
    
    /// Get Hawaiian weekday name for a given date
    public static func weekday(for date: Date) -> String? {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekdays[weekday]
    }
    
    /// Get Hawaiian month name for a given date
    public static func month(for date: Date) -> String? {
        let month = Calendar.current.component(.month, from: date)
        return months[month]
    }
}
