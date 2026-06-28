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

    // MARK: - Backward-compatible model decoding

    func testLegacyJSONDecodesWithDefaults() throws {
        // JSON written by an earlier app version — no design-option fields.
        let json = """
        {"id":"legacy1","title":"Legacy","byline":"Dr","publishDate":"2025-01-01T00:00:00Z","category":"Lupus","summary":"s","body":"b","isUserAuthored":true}
        """
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let a = try dec.decode(Article.self, from: Data(json.utf8))
        XCTAssertEqual(a.titleStyle, .standard)
        XCTAssertNil(a.coverImageName)
        XCTAssertNil(a.accentColorHex)
        XCTAssertTrue(a.imageAttachmentNames.isEmpty)
        XCTAssertEqual(a.ownedImageNames, [])
    }

    func testNewFieldsRoundTripThroughCodable() throws {
        let original = Article(
            id: "r", title: "T", byline: "B",
            publishDate: Date(timeIntervalSince1970: 1000),
            category: .gout, summary: "s", body: "b", isUserAuthored: true,
            coverImageName: "cover.jpg", accentColorHex: "#ABCDEF",
            titleStyle: .rounded, imageAttachmentNames: ["x.png", "y.png"]
        )
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let back = try dec.decode(Article.self, from: enc.encode(original))
        XCTAssertEqual(original, back)
        XCTAssertEqual(back.ownedImageNames, ["cover.jpg", "x.png", "y.png"])
    }

    func testCreatePostStoresDesignFields() {
        let store = makeStoreWithStubArticles()
        store.createPost(
            title: "Art", category: .ra, summary: "s", body: "# H\n\nbody", byline: "Dr",
            coverImageName: "c.jpg", accentColorHex: "#112233",
            titleStyle: .serif, imageAttachmentNames: ["a.png"]
        )
        let post = store.articles.first
        XCTAssertEqual(post?.coverImageName, "c.jpg")
        XCTAssertEqual(post?.accentColorHex, "#112233")
        XCTAssertEqual(post?.titleStyle, .serif)
        XCTAssertEqual(post?.imageAttachmentNames, ["a.png"])
    }

    // MARK: - Markdown parsing + insertion helpers

    func testMarkdownParserProducesExpectedBlocks() {
        let md = "# Title\n\nIntro para.\n\n- one\n- two\n\n1. first\n2. second\n\n> a quote\n\n---\n\n![x](pic.png)"
        let blocks = MarkdownParser.parse(md)
        XCTAssertEqual(blocks.count, 7)
        guard case .heading(1, "Title") = blocks[0] else { return XCTFail("block 0") }
        guard case .paragraph = blocks[1] else { return XCTFail("block 1") }
        guard case .bullets(let b) = blocks[2] else { return XCTFail("block 2") }
        XCTAssertEqual(b, ["one", "two"])
        guard case .numbered(let n) = blocks[3] else { return XCTFail("block 3") }
        XCTAssertEqual(n, ["first", "second"])
        guard case .quote(let q) = blocks[4] else { return XCTFail("block 4") }
        XCTAssertEqual(q, "a quote")
        guard case .divider = blocks[5] else { return XCTFail("block 5") }
        guard case .image(let name, _) = blocks[6] else { return XCTFail("block 6") }
        XCTAssertEqual(name, "pic.png")
    }

    func testWrapBoldAroundSelection() {
        let (text, sel) = MDInsert.wrap("hello world", NSRange(location: 6, length: 5), marker: "**")
        XCTAssertEqual(text, "hello **world**")
        XCTAssertEqual(sel, NSRange(location: 8, length: 5))
    }

    func testHeadingPrefixReplacesExistingMarker() {
        let (text, _) = MDInsert.transformLines("## old", NSRange(location: 0, length: 0)) { _, line in
            "# " + MDInsert.stripMarkers(line)
        }
        XCTAssertEqual(text, "# old")
    }

    func testPlainTextStripsMarkdownForSpeech() {
        let spoken = MarkdownParser.plainText("# Heading\n\n**Bold** and *italic*.\n\n![x](p.png)\n\n- item")
        XCTAssertFalse(spoken.contains("#"))
        XCTAssertFalse(spoken.contains("*"))
        XCTAssertFalse(spoken.contains("p.png"))
        XCTAssertTrue(spoken.contains("Bold"))
        XCTAssertTrue(spoken.contains("item"))
    }

    // MARK: - Category encoding (short code <-> legacy full name)

    func testShortCodeCategoryDecodes() throws {
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let json = #"{"id":"x","title":"T","byline":"B","publishDate":"2025-01-01T00:00:00Z","category":"psa","summary":"s","body":"b"}"#
        XCTAssertEqual(try dec.decode(Article.self, from: Data(json.utf8)).category, .psa)
    }

    func testLegacyFullNameCategoryDecodes() throws {
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let json = #"{"id":"x","title":"T","byline":"B","publishDate":"2025-01-01T00:00:00Z","category":"Rheumatoid Arthritis","summary":"s","body":"b"}"#
        XCTAssertEqual(try dec.decode(Article.self, from: Data(json.utf8)).category, .ra)
    }

    func testCategoryEncodesCanonicalShortCode() throws {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let s = String(data: try enc.encode(makeArticle(category: .osteoarthritis)), encoding: .utf8)!
        XCTAssertTrue(s.contains("\"category\":\"osteoarthritis\""))
        XCTAssertFalse(s.contains("Osteoarthritis"))  // full display name must not be persisted
    }

    func testRealBundledArticlesDecodeAllEight() throws {
        // Decode the actual shipped seed (short category codes) from the source tree.
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let json = root.appendingPathComponent("Sources/RheumPie/Resources/articles.json")
        guard let data = try? Data(contentsOf: json) else { throw XCTSkip("articles.json not found at \(json.path)") }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let arts = try dec.decode([Article].self, from: data)
        XCTAssertEqual(arts.count, 8, "All 8 seed articles must decode")
        XCTAssertTrue(Set(arts.map(\.category)).isSuperset(of: [.ra, .lupus, .gout, .psa, .osteoarthritis]))
    }

    func testUserPostsSkipMalformedRecord() {
        // One valid post + one missing the required "title" — the bad one must be
        // skipped, not nuke the whole array.
        let good = #"{"id":"u1","title":"Good","byline":"Dr","publishDate":"2025-01-01T00:00:00Z","category":"ra","summary":"s","body":"b","isUserAuthored":true}"#
        let bad = #"{"id":"u2","byline":"Dr","publishDate":"2025-01-01T00:00:00Z","category":"ra","summary":"s","body":"b","isUserAuthored":true}"#
        UserDefaults.standard.set(Data("[\(good),\(bad)]".utf8), forKey: "com.zrottmann.rheumpie.userPosts")
        let store = ArticleStore()
        store.load()
        XCTAssertTrue(store.articles.contains { $0.id == "u1" })
        XCTAssertFalse(store.articles.contains { $0.id == "u2" })
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
