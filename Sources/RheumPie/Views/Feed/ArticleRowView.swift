import SwiftUI

/// Article card used in the feed and bookmarks list.
///
/// Layout: a thin category-color accent bar on top, then padded content
/// (category badge, title, summary, footer). White card background with a
/// subtle shadow pops against the grouped gray list background.
struct ArticleRowView: View {
    let article: Article
    let isBookmarked: Bool

    private var accent: Color { article.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Optional hero/cover image
            if let cover = article.coverImageName, let ui = ImageStore.image(named: cover) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }

            // Colored accent bar — editorial identity marker (per-post accent)
            Rectangle()
                .fill(accent)
                .frame(height: Theme.Card.accentBarHeight)

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                // Top row: category badge + status icons
                HStack(alignment: .center, spacing: Theme.Spacing.xsmall) {
                    CategoryBadge(category: article.category, accent: accent)
                    Spacer()
                    if article.isUserAuthored {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Your post")
                    }
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(accent)
                            .accessibilityLabel("Bookmarked")
                    }
                }

                // Title
                Text(article.title)
                    .font(Theme.Font.articleTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Summary
                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Footer: date + read time
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
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.top, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.medium)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Card.cornerRadius, style: .continuous))
        .shadow(
            color: .black.opacity(Theme.Card.shadowOpacity),
            radius: Theme.Card.shadowRadius,
            x: 0,
            y: 2
        )
    }
}
