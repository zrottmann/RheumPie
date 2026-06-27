import SwiftUI

/// Unified sheet state for the feed — reader, new post, or edit post.
private enum FeedSheet: Identifiable {
    case reader(Article)
    case newPost
    case editPost(Article)

    var id: String {
        switch self {
        case .reader(let a): return "reader-\(a.id)"
        case .newPost: return "new-post"
        case .editPost(let a): return "edit-\(a.id)"
        }
    }
}

/// Main article feed — tab 1.
struct FeedView: View {
    @Environment(ArticleStore.self) private var store
    @State private var activeSheet: FeedSheet? = nil
    @State private var searchText = ""

    // MARK: - Filtered article partitions

    private var displayedArticles: [Article] {
        let base = store.filteredArticles
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) ||
            $0.summary.lowercased().contains(q) ||
            $0.category.rawValue.lowercased().contains(q)
        }
    }

    private var userPosts: [Article] { displayedArticles.filter { $0.isUserAuthored } }
    private var seedArticles: [Article] { displayedArticles.filter { !$0.isUserAuthored } }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterView(selectedCategory: Binding(
                    get: { store.selectedCategory },
                    set: { store.selectCategory($0) }
                ))
                .background(.bar)

                Divider()

                feedList
            }
            .navigationTitle("Rheum Pie")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .newPost
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Write new post")
                }
            }
            .searchable(text: $searchText, prompt: "Search articles")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .reader(let article):
                    ReaderView(article: article)
                case .newPost:
                    PostEditorView(editing: nil)
                case .editPost(let article):
                    PostEditorView(editing: article)
                }
            }
            .overlay {
                if displayedArticles.isEmpty {
                    ContentUnavailableView(
                        "No Articles",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Try a different filter or search term.")
                    )
                }
            }
        }
    }

    // MARK: - Feed list

    @ViewBuilder
    private var feedList: some View {
        List {
            if !userPosts.isEmpty {
                Section {
                    ForEach(userPosts) { article in
                        articleRow(article)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    store.deletePost(article)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    activeSheet = .editPost(article)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                } header: {
                    feedSectionHeader("Your Posts")
                }
            }

            if !seedArticles.isEmpty {
                Section {
                    ForEach(seedArticles) { article in
                        articleRow(article)
                    }
                } header: {
                    if !userPosts.isEmpty {
                        feedSectionHeader("From Your Rheumatologist")
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .scrollContentBackground(.hidden)
    }

    private func articleRow(_ article: Article) -> some View {
        Button {
            activeSheet = .reader(article)
        } label: {
            ArticleRowView(
                article: article,
                isBookmarked: store.isBookmarked(article)
            )
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func feedSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Font.sectionHeader)
            .foregroundStyle(.secondary)
            .textCase(nil)
    }
}
