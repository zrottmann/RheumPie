import Foundation
import Observation

/// Central store for articles and bookmark state.
@MainActor
@Observable
final class ArticleStore {
    // MARK: - State

    private(set) var articles: [Article] = []
    private(set) var selectedCategory: ArticleCategory? = nil
    private var bookmarkIDs: Set<String> = []

    // MARK: - Computed

    var filteredArticles: [Article] {
        guard let cat = selectedCategory else { return articles }
        return articles.filter { $0.category == cat }
    }

    func isBookmarked(_ article: Article) -> Bool {
        bookmarkIDs.contains(article.id)
    }

    // MARK: - Intent

    func selectCategory(_ category: ArticleCategory?) {
        selectedCategory = category
    }

    func toggleBookmark(_ article: Article) {
        if bookmarkIDs.contains(article.id) {
            bookmarkIDs.remove(article.id)
        } else {
            bookmarkIDs.insert(article.id)
        }
        persistBookmarks()
    }

    var bookmarkedArticles: [Article] {
        articles.filter { bookmarkIDs.contains($0.id) }
    }

    // MARK: - Testing support

    /// Injects articles directly, bypassing bundle loading. Used in unit tests only.
    func injectArticlesForTesting(_ injected: [Article]) {
        articles = injected
    }

    // MARK: - Loading

    func load() {
        articles = loadFromBundle()
        bookmarkIDs = loadPersistedBookmarks()
    }

    private func loadFromBundle() -> [Article] {
        guard let url = Bundle.main.url(forResource: "articles", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Article].self, from: data)
        } catch {
            return []
        }
    }

    // MARK: - Persistence (UserDefaults)

    private let bookmarksKey = "com.zrottmann.rheumpie.bookmarks"

    private func loadPersistedBookmarks() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: bookmarksKey) ?? []
        return Set(array)
    }

    private func persistBookmarks() {
        UserDefaults.standard.set(Array(bookmarkIDs), forKey: bookmarksKey)
    }
}
