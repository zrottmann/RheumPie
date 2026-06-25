import SwiftUI

/// Main article feed — tab 1.
struct FeedView: View {
    @Environment(ArticleStore.self) private var store
    @State private var selectedArticle: Article? = nil
    @State private var searchText = ""

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

    var body: some View {
        @Bindable var storeBinding = store
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterView(selectedCategory: Binding(
                    get: { store.selectedCategory },
                    set: { store.selectCategory($0) }
                ))
                Divider()
                List(displayedArticles) { article in
                    Button {
                        selectedArticle = article
                    } label: {
                        ArticleRowView(
                            article: article,
                            isBookmarked: store.isBookmarked(article)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search articles")
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
            .navigationTitle("Rheum Pie")
            .sheet(item: $selectedArticle) { article in
                ReaderView(article: article)
            }
        }
    }
}
