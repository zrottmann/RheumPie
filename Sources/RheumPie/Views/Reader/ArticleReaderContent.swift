import SwiftUI

/// The scrollable presentation of an article — cover image, header, styled title,
/// byline, accent rule, Markdown body, embedded images/sketches, and the required
/// disclaimer. Shared by `ReaderView` and the editor's live preview so the author
/// sees exactly the published layout.
struct ArticleReaderContent: View {
    let article: Article

    var body: some View {
        let accent = article.accentColor
        VStack(alignment: .leading, spacing: 0) {
            if let cover = article.coverImageName, let ui = ImageStore.image(named: cover) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.bottom, Theme.Spacing.medium)
            }

            HStack {
                CategoryBadge(category: article.category, accent: accent)
                Spacer()
                Label("\(article.estimatedReadMinutes) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, Theme.Spacing.medium)

            Text(article.title)
                .font(.largeTitle.weight(.bold))
                .fontDesign(article.titleStyle.fontDesign)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Theme.Spacing.small)

            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: "person.circle.fill").foregroundStyle(accent)
                Text(article.byline)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(article.publishDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, Theme.Spacing.medium)

            Rectangle().fill(accent).frame(height: 2).padding(.bottom, Theme.Spacing.large)

            MarkdownContentView(markdown: article.body, accent: accent)
                .padding(.bottom, Theme.Spacing.medium)

            DisclaimerView(accent: accent)
                .padding(.top, Theme.Spacing.small)
                .padding(.bottom, Theme.Spacing.large)
        }
    }
}

/// "Patient Education Only" callout — required on every article.
struct DisclaimerView: View {
    var accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Label("Patient Education Only", systemImage: "info.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)

                Text("This article is for patient education only and is not a substitute for professional medical advice. Always talk to your rheumatologist before making any changes to your treatment.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.medium)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
