import XCTest
@testable import RheumPie

// NOTE: @MainActor @Observable models must be tested on the main actor.
@MainActor
final class ArticleStoreTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // Prevent persisted user posts from leaking between tests.
        UserDefaults.standard.removeObject(forKey: "com.zrottmann.rheumpie.userPosts")
    }

    // MARK: - Seed loading

    func testLoadPopulatesArticles() async throws {
        let store = ArticleStore()
        // load() reads from the test bundle which includes articles.json
        store.load()
        XCTAssertFalse(store.articles.isEmpty, "Should load seed articles from bundle JSON")
    }

    func testSeedContainsExpectedCategories() async throws {
        let store = ArticleStore()
        store.load()
        let categories = Set(store.articles.map(\.category))
        XCTAssertTrue(categories.contains(.ra), "Seed should include RA articles")
        XCTAssertTrue(categories.contains(.lupus), "Seed should include Lupus articles")
        XCTAssertTrue(categories.contains(.gout), "Seed should include Gout articles")
    }

    // MARK: - Category filter

    func testNoFilterReturnsAll() async throws {
        let store = makeStoreWithStubArticles()
        store.selectCategory(nil)
        XCTAssertEqual(store.filteredArticles.count, store.articles.count)
    }

    func testFilterByCategory() async throws {
        let store = makeStoreWithStubArticles()
        store.selectCategory(.ra)
        XCTAssertTrue(store.filteredArticles.allSatisfy { $0.category == .ra })
    }

    func testFilterReturnsEmptyWhenNoMatch() async throws {
        let store = makeStoreWithStubArticles()
        store.selectCategory(.osteoarthritis)
        // Stub articles have no OA articles
        XCTAssertTrue(store.filteredArticles.isEmpty)
    }

    func testClearFilterRestoresAll() async throws {
        let store = makeStoreWithStubArticles()
        store.selectCategory(.ra)
        store.selectCategory(nil)
        XCTAssertEqual(store.filteredArticles.count, store.articles.count)
    }

    // MARK: - Bookmark toggle

    func testBookmarkToggleOn() async throws {
        let store = makeStoreWithStubArticles()
        let article = store.articles[0]
        XCTAssertFalse(store.isBookmarked(article))
        store.toggleBookmark(article)
        XCTAssertTrue(store.isBookmarked(article))
    }

    func testBookmarkToggleOff() async throws {
        let store = makeStoreWithStubArticles()
        let article = store.articles[0]
        store.toggleBookmark(article)
        store.toggleBookmark(article)
        XCTAssertFalse(store.isBookmarked(article))
    }

    func testBookmarkedArticlesContainsOnlyBookmarked() async throws {
        let store = makeStoreWithStubArticles()
        let a1 = store.articles[0]
        let a2 = store.articles[1]
        store.toggleBookmark(a1)
        XCTAssertTrue(store.bookmarkedArticles.contains(where: { $0.id == a1.id }))
        XCTAssertFalse(store.bookmarkedArticles.contains(where: { $0.id == a2.id }))
    }

    func testMultipleBookmarks() async throws {
        let store = makeStoreWithStubArticles()
        store.articles.forEach { store.toggleBookmark($0) }
        XCTAssertEqual(store.bookmarkedArticles.count, store.articles.count)
    }

    // MARK: - Estimated read time

    func testShortBodyHasMinimumReadTime() {
        let article = makeArticle(body: "Short body.")
        XCTAssertEqual(article.estimatedReadMinutes, 1)
    }

    func testLongBodyHasMoreReadTime() {
        // 400 words should be 2 minutes at 200 wpm
        let words = Array(repeating: "word", count: 400).joined(separator: " ")
        let article = makeArticle(body: words)
        XCTAssertEqual(article.estimatedReadMinutes, 2)
    }

    // MARK: - User post authoring

    func testCreatePostAppearsFirst() {
        let store = makeStoreWithStubArticles()
        store.createPost(
            title: "My First Post",
            category: .ra,
            summary: "A summary.",
            body: "Body content here.",
            byline: "Dr. Test"
        )
        XCTAssertEqual(store.articles.first?.title, "My First Post")
        XCTAssertTrue(store.articles.first?.isUserAuthored == true)
    }

    func testCreatePostIncrementsCount() {
        let store = makeStoreWithStubArticles()
        let before = store.articles.count
        store.createPost(title: "Post", category: .general, summary: "S", body: "Body text.", byline: "Dr.")
        XCTAssertEqual(store.articles.count, before + 1)
    }

    func testUpdatePostChangesTitle() {
        let store = makeStoreWithStubArticles()
        store.createPost(title: "Original", category: .general, summary: "S", body: "Body.", byline: "Dr.")
        guard let created = store.articles.first(where: { $0.isUserAuthored }) else {
            return XCTFail("No user post found after createPost")
        }
        let updated = Article(
            id: created.id,
            title: "Updated Title",
            byline: created.byline,
            publishDate: created.publishDate,
            category: created.category,
            summary: created.summary,
            body: created.body,
            isUserAuthored: true
        )
        store.updatePost(updated)
        XCTAssertEqual(store.articles.first(where: { $0.id == created.id })?.title, "Updated Title")
    }

    func testDeletePostRemovesIt() {
        let store = makeStoreWithStubArticles()
        store.createPost(title: "To Delete", category: .general, summary: "S", body: "Body.", byline: "Dr.")
        let before = store.articles.count
        guard let post = store.articles.first(where: { $0.isUserAuthored }) else {
            return XCTFail("No user post found after createPost")
        }
        store.deletePost(post)
        XCTAssertFalse(store.articles.contains(where: { $0.id == post.id }))
        XCTAssertEqual(store.articles.count, before - 1)
    }

    func testDeletePostAlsoRemovesBookmark() {
        let store = makeStoreWithStubArticles()
        store.createPost(title: "Bookmarked Post", category: .ra, summary: "S", body: "Body.", byline: "Dr.")
        guard let post = store.articles.first(where: { $0.isUserAuthored }) else {
            return XCTFail("No user post found after createPost")
        }
        store.toggleBookmark(post)
        XCTAssertTrue(store.isBookmarked(post))
        store.deletePost(post)
        XCTAssertFalse(store.isBookmarked(post))
    }

    func testCannotDeleteSeedArticle() {
        let store = makeStoreWithStubArticles()
        guard let seed = store.articles.first(where: { !$0.isUserAuthored }) else {
            return XCTFail("No seed article to test with")
        }
        let before = store.articles.count
        store.deletePost(seed)  // guard in deletePost: !isUserAuthored → no-op
        XCTAssertEqual(store.articles.count, before)
    }

    // MARK: - Helpers

    private func makeStoreWithStubArticles() -> ArticleStore {
        let store = ArticleStore()
        store.injectArticlesForTesting(stubArticles())
        return store
    }

    private func stubArticles() -> [Article] {
        [
            makeArticle(id: "t1", category: .ra, body: "RA article body text with enough words here."),
            makeArticle(id: "t2", category: .lupus, body: "Lupus article body text with some words."),
            makeArticle(id: "t3", category: .gout, body: "Gout article body text."),
        ]
    }

    private func makeArticle(
        id: String = "test-id",
        category: ArticleCategory = .general,
        body: String = "Test body."
    ) -> Article {
        Article(
            id: id,
            title: "Test Article",
            byline: "Test Author",
            publishDate: Date(),
            category: category,
            summary: "Test summary.",
            body: body
        )
    }
}
