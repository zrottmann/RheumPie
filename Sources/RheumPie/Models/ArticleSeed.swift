import Foundation

/// Fallback in-code seed used only if the JSON file is missing from the bundle.
/// The authoritative seed is Resources/articles.json.
enum ArticleSeed {
    static let placeholder: [Article] = []
}
