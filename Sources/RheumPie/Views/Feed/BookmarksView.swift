import SwiftUI

/// Bookmarks tab — lists articles the user has saved.
struct BookmarksView: View {
    @Environment(ArticleStore.self) private var store
    @State private var selectedArticle: Article? = nil

    var body: some View {
        NavigationStack {
            Group {
                if store.bookmarkedArticles.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark.slash",
                        description: Text("Tap the bookmark icon while reading an article to save it here.")
                    )
                } else {
                    List(store.bookmarkedArticles) { article in
                        Button {
                            selectedArticle = article
                        } label: {
                            ArticleRowView(article: article, isBookmarked: true)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.toggleBookmark(article)
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Bookmarks")
            .sheet(item: $selectedArticle) { article in
                ReaderView(article: article)
            }
        }
    }
}
