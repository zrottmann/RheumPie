import SwiftUI

/// Single row in the article feed list.
struct ArticleRowView: View {
    let article: Article
    let isBookmarked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(article.category.shortLabel, systemImage: article.category.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                Spacer()
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .imageScale(.small)
                        .foregroundStyle(Color.accentColor)
                }
            }

            Text(article.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(article.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Text(article.publishDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Label("\(article.estimatedReadMinutes) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
