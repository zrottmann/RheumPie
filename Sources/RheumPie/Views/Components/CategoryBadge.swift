import SwiftUI

/// A pill-shaped category label with icon, tinted per category.
struct CategoryBadge: View {
    let category: ArticleCategory

    var body: some View {
        Label {
            Text(category.shortLabel)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: category.systemImage)
                .font(.caption)
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.12))
        .clipShape(Capsule())
    }
}
