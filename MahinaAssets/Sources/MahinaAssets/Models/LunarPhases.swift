import Foundation

/// Complete lookup table of Hawaiian lunar calendar phases with traditional guidance.
///
/// Contains all 30 phases of the Hawaiian lunar calendar system with their names,
/// descriptions, and traditional guidance for planting and fishing activities.
public struct LunarPhases {

    // MARK: - Phase Data

    /// Phase information for each of the 30 lunar days
    /// Each entry contains: (day, name, description, planting guidance, fishing guidance)
    public static let phases:
        [(day: Int, name: String, description: String, planting: String, fishing: String)] = [
            (
                1, "Hilo",
                "Slender new-moon, sliver at sunset",
                "Plant underground crops that 'hide' in the soil",
                "Reef fish hide, deep-sea fishing is good"
            ),
            (
                2, "Hoaka",
                "Second night, thin crescent 'spirit' night",
                "Limit planting, observe conditions",
                "Fish are frightened away, poor fishing"
            ),
            (
                3, "Kūkahi",
                "First night of Kū, moon growing",
                "Good time to plant ʻuala and kalo",
                "Good fishing conditions beginning to change"
            ),
            (
                4, "Kūlua",
                "Second night of Kū, continued growth",
                "Continue planting upright strong-growing crops",
                "Good fishing period"
            ),
            (
                5, "Kūkolu",
                "Third night of Kū, steady growth continues",
                "Plant crops you want to grow tall and strong",
                "Good fishing period"
            ),
            (
                6, "Kūpau",
                "Fourth night of Kū, end of Kū phase",
                "Finish planting of taro and other upright crops",
                "Good fishing period"
            ),
            (
                7, "ʻOlekūkahi",
                "First ʻOle night, considered unproductive",
                "Avoid planting, focus on weeding and maintenance",
                "Fishing poor due to high tides and rough ocean"
            ),
            (
                8, "ʻOlekūlua",
                "Second ʻOle night, unproductive period continues",
                "Avoid planting, continue garden upkeep only",
                "Fishing remains poor, rough conditions"
            ),
            (
                9, "ʻOlekūkolu",
                "Third ʻOle night, rough conditions persist",
                "Planting discouraged, maintain and tidy fields",
                "Fishing poor, seas unsettled"
            ),
            (
                10, "ʻOlepau",
                "Fourth ʻOle night, end of rough period",
                "Little planting, finish maintenance work",
                "Fishing still poor, conditions moderating"
            ),
            (
                11, "Huna",
                "Hidden-horns moon, small but rounding",
                "Good for root vegetables and gourds that 'hide'",
                "Good fishing as fish hide in their holes"
            ),
            (
                12, "Mōhalu",
                "Sacred night to Kāne, moon nearly full",
                "Good for planting vegetables to mirror the round moon",
                "Sea foods traditionally kapu, avoid fishing"
            ),
            (
                13, "Hua",
                "First of the four full moons, 'egg fruit seed'",
                "Very good for planting fruiting and seed crops",
                "Good-luck night for fishing"
            ),
            (
                14, "Akua",
                "Second full moon, sacred to the gods",
                "Favorable for planting with offerings to the gods",
                "Good night for fishing"
            ),
            (
                15, "Hoku",
                "Fullest of the full moons, peak brightness",
                "Best for crops planted in rows",
                "Good fishing under bright full moon"
            ),
            (
                16, "Māhealani",
                "Last of the four full moons",
                "Good for all kinds of planting and work",
                "Good fishing, people take full advantage"
            ),
            (
                17, "Kulu",
                "Moon following the full-moon series",
                "Time to harvest and offer first fruits",
                "Fishing considered good"
            ),
            (
                18, "Lāʻaukūkahi",
                "First Lāʻau night, associated with trees and plants",
                "Focus on trees and medicinal plants, avoid tender fruit crops",
                "Fishing acceptable, attention on gathering plant medicines"
            ),
            (
                19, "Lāʻaukūlua",
                "Second Lāʻau night, tree focus continues",
                "Continue work with trees and herbs, avoid woody fruit set",
                "Fishing moderate, not the primary focus"
            ),
            (
                20, "Lāʻaupau",
                "Third Lāʻau night, completion of tree phase",
                "Complete work with trees and medicinal plants",
                "Fishing moderate, period centered on plants and healing"
            ),
            (
                21, "ʻOlekūkahi",
                "Unproductive ʻOle night returns",
                "Avoid planting, good for weeding and cleaning fields",
                "Fishing generally avoided, focus on prayers"
            ),
            (
                22, "ʻOlekūlua",
                "Second unproductive ʻOle night",
                "Continue field maintenance rather than planting",
                "Fishing avoided, little activity at sea"
            ),
            (
                23, "ʻOlepau",
                "Final ʻOle night, dedicated to Kāloa and Kanaloa",
                "Avoid planting, offer prayers instead",
                "Fishing generally avoided, day of worship"
            ),
            (
                24, "Kāloakūkahi",
                "First Kāloa night, beginning of Kāloa series",
                "Plant long-stemmed crops and vine plants",
                "Good fishing, especially for shellfish"
            ),
            (
                25, "Kāloakūlua",
                "Second Kāloa night, vine planting continues",
                "Continue planting vines and long-stemmed plants",
                "Good fishing, especially shellfish"
            ),
            (
                26, "Kāloapau",
                "Third Kāloa night, Kāloa phase completes",
                "Finish planting vines and long-stemmed crops",
                "Good fishing, shellfish and reef foods favored"
            ),
            (
                27, "Kāne",
                "Sacred night of worship to Kāne and Lono",
                "Little or no planting, focus on kapu observances",
                "Fishing generally set aside for prayer"
            ),
            (
                28, "Lono",
                "Second worship night, dedicated to Lono and rain",
                "No major planting, prayers for rain and fertility",
                "Fishing typically limited, focus on ceremony"
            ),
            (
                29, "Mauli",
                "Moon rises with daylight, 'shadow of life'",
                "Light planting or garden preparation",
                "Fishing encouraged, lower tides favor activity"
            ),
            (
                30, "Muku",
                "Dark new-moon night, final phase",
                "Rest from planting and prepare for new cycle",
                "Fishing considered good on this dark moon"
            ),
        ]

    // MARK: - Helper Methods

    /// Get phase data for a specific lunar day (1-30)
    public static func phase(for day: Int) -> (
        day: Int, name: String, description: String, planting: String, fishing: String
    )? {
        return phases.first(where: { $0.day == day })
    }
}
