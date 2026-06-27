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
    /// True for posts created within the app by the rheumatologist.
    var isUserAuthored: Bool = false

    /// Approximate reading time computed from body word count.
    var estimatedReadMinutes: Int {
        let words = body.split(separator: " ").count
        return max(1, Int((Double(words) / 200.0).rounded(.up)))
    }
}

// MARK: - Codable (custom to gracefully handle optional isUserAuthored in legacy JSON)

extension Article {
    private enum CodingKeys: String, CodingKey {
        case id, title, byline, publishDate, category, summary, body, isUserAuthored
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        byline = try c.decode(String.self, forKey: .byline)
        publishDate = try c.decode(Date.self, forKey: .publishDate)
        category = try c.decode(ArticleCategory.self, forKey: .category)
        summary = try c.decode(String.self, forKey: .summary)
        body = try c.decode(String.self, forKey: .body)
        isUserAuthored = try c.decodeIfPresent(Bool.self, forKey: .isUserAuthored) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(byline, forKey: .byline)
        try c.encode(publishDate, forKey: .publishDate)
        try c.encode(category, forKey: .category)
        try c.encode(summary, forKey: .summary)
        try c.encode(body, forKey: .body)
        try c.encode(isUserAuthored, forKey: .isUserAuthored)
    }
}

// MARK: - Category

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
