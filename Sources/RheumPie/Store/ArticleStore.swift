import Foundation
import Observation

/// Central store for articles, bookmarks, and user-authored posts.
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

    // MARK: - Intent: filtering & bookmarks

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

    // MARK: - Intent: user post authoring

    func createPost(title: String, category: ArticleCategory, summary: String, body: String, byline: String) {
        let trimmedByline = byline.trimmingCharacters(in: .whitespaces)
        let article = Article(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespaces),
            byline: trimmedByline.isEmpty ? "Your Rheumatologist" : trimmedByline,
            publishDate: Date(),
            category: category,
            summary: summary.trimmingCharacters(in: .whitespaces),
            body: body.trimmingCharacters(in: .whitespaces),
            isUserAuthored: true
        )
        articles.insert(article, at: 0)
        persistUserPosts()
    }

    func updatePost(_ updated: Article) {
        guard let idx = articles.firstIndex(where: { $0.id == updated.id }),
              articles[idx].isUserAuthored else { return }
        articles[idx] = updated
        persistUserPosts()
    }

    func deletePost(_ article: Article) {
        guard article.isUserAuthored else { return }
        articles.removeAll { $0.id == article.id }
        bookmarkIDs.remove(article.id)
        persistBookmarks()
        persistUserPosts()
    }

    // MARK: - Testing support

    /// Injects articles directly, bypassing bundle loading. Used in unit tests only.
    func injectArticlesForTesting(_ injected: [Article]) {
        articles = injected
    }

    /// Clears persisted user posts. Used in unit tests only.
    func clearUserPostsForTesting() {
        UserDefaults.standard.removeObject(forKey: userPostsKey)
    }

    // MARK: - Loading

    func load() {
        let seed = loadFromBundle()
        let user = loadUserPosts()
        // User posts sort first so the rheumatologist's latest entries lead the feed.
        articles = user + seed
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

    // MARK: - Persistence: bookmarks

    private let bookmarksKey = "com.zrottmann.rheumpie.bookmarks"

    private func loadPersistedBookmarks() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: bookmarksKey) ?? []
        return Set(array)
    }

    private func persistBookmarks() {
        UserDefaults.standard.set(Array(bookmarkIDs), forKey: bookmarksKey)
    }

    // MARK: - Persistence: user posts

    private let userPostsKey = "com.zrottmann.rheumpie.userPosts"

    private func loadUserPosts() -> [Article] {
        guard let data = UserDefaults.standard.data(forKey: userPostsKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Article].self, from: data)) ?? []
    }

    private func persistUserPosts() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let posts = articles.filter { $0.isUserAuthored }
        if let data = try? encoder.encode(posts) {
            UserDefaults.standard.set(data, forKey: userPostsKey)
        }
    }
}
