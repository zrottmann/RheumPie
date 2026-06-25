import Foundation

/// A single patient-education article authored by the rheumatologist.
struct Article: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let byline: String
    let publishDate: Date
    let category: ArticleCategory
    let summary: String
    /// Full body text. Paragraphs separated by "\n\n".
    let body: String
    /// Approximate reading time computed from body word count.
    var estimatedReadMinutes: Int {
        let words = body.split(separator: " ").count
        return max(1, Int((Double(words) / 200.0).rounded(.up)))
    }
}

/// Broad condition categories for filtering.
enum ArticleCategory: String, Codable, CaseIterable, Identifiable {
    case general = "General"
    case ra = "Rheumatoid Arthritis"
    case lupus = "Lupus"
    case gout = "Gout"
    case psa = "Psoriatic Arthritis"
    case osteoarthritis = "Osteoarthritis"

    var id: String { rawValue }

    /// Short display label used in filter chips.
    var shortLabel: String {
        switch self {
        case .general: return "General"
        case .ra: return "RA"
        case .lupus: return "Lupus"
        case .gout: return "Gout"
        case .psa: return "PsA"
        case .osteoarthritis: return "OA"
        }
    }

    /// SF Symbol name that represents the category.
    var systemImage: String {
        switch self {
        case .general: return "heart.text.square"
        case .ra: return "hand.point.up.braille"
        case .lupus: return "sun.max.trianglebadge.exclamationmark"
        case .gout: return "figure.walk"
        case .psa: return "skin"
        case .osteoarthritis: return "figure.strengthtraining.traditional"
        }
    }
}
