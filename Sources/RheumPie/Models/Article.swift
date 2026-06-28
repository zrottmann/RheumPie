import Foundation

/// A single patient-education article authored by the rheumatologist.
///
/// `body` is treated as **Markdown** going forward (headings, lists, quotes,
/// dividers, inline images, emphasis, links). The design-option fields below are
/// all optional and decoded with `decodeIfPresent`, so the seeded articles and
/// any posts written by earlier app versions keep decoding unchanged.
struct Article: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let byline: String
    let publishDate: Date
    let category: ArticleCategory
    let summary: String
    /// Full body text, authored as Markdown. Paragraphs separated by "\n\n".
    let body: String
    /// True for posts created within the app by the rheumatologist.
    var isUserAuthored: Bool = false

    // MARK: - Authoring design options (optional, backward-compatible)

    /// Filename (in the app's Documents dir) of the article's hero/cover image.
    var coverImageName: String? = nil
    /// Per-post accent color as "#RRGGBB". When nil, the category color is used.
    var accentColorHex: String? = nil
    /// Title typography chosen by the author.
    var titleStyle: TitleStyle = .standard
    /// Filenames (Documents dir) of inline images + sketches the post owns.
    var imageAttachmentNames: [String] = []

    /// Approximate reading time computed from body word count.
    var estimatedReadMinutes: Int {
        let words = body.split(whereSeparator: { $0 == " " || $0 == "\n" }).count
        return max(1, Int((Double(words) / 200.0).rounded(.up)))
    }

    /// Every image file (Documents dir) this article owns — cover + attachments.
    /// Used to clean up on edit/delete.
    var ownedImageNames: [String] {
        (coverImageName.map { [$0] } ?? []) + imageAttachmentNames
    }
}

// MARK: - Codable (custom to gracefully handle optional fields in legacy JSON)

extension Article {
    private enum CodingKeys: String, CodingKey {
        case id, title, byline, publishDate, category, summary, body, isUserAuthored
        case coverImageName, accentColorHex, titleStyle, imageAttachmentNames
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
        coverImageName = try c.decodeIfPresent(String.self, forKey: .coverImageName)
        accentColorHex = try c.decodeIfPresent(String.self, forKey: .accentColorHex)
        titleStyle = try c.decodeIfPresent(TitleStyle.self, forKey: .titleStyle) ?? .standard
        imageAttachmentNames = try c.decodeIfPresent([String].self, forKey: .imageAttachmentNames) ?? []
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
        try c.encodeIfPresent(coverImageName, forKey: .coverImageName)
        try c.encodeIfPresent(accentColorHex, forKey: .accentColorHex)
        try c.encode(titleStyle, forKey: .titleStyle)
        try c.encode(imageAttachmentNames, forKey: .imageAttachmentNames)
    }
}

// MARK: - Title typography

/// Curated title typography styles the author can pick per post.
enum TitleStyle: String, Codable, CaseIterable, Identifiable {
    case standard = "Default"
    case serif = "Serif"
    case rounded = "Rounded"

    var id: String { rawValue }
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

    /// Canonical on-disk short code — the form used by articles.json and the web
    /// app. `rawValue` stays the full display name so UI that shows it is unaffected.
    var code: String {
        switch self {
        case .general: return "general"
        case .ra: return "ra"
        case .lupus: return "lupus"
        case .gout: return "gout"
        case .psa: return "psa"
        case .osteoarthritis: return "osteoarthritis"
        }
    }

    // Custom Codable: decode the short code OR the legacy full display name (so the
    // seed JSON and build 3/4 user posts both load); encode the canonical short code.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if let byCode = ArticleCategory.allCases.first(where: { $0.code == raw }) {
            self = byCode
        } else {
            self = ArticleCategory(rawValue: raw) ?? .general
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(code)
    }
}
