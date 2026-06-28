import SwiftUI

/// A pill-shaped category label with icon, tinted per category.
struct CategoryBadge: View {
    let category: ArticleCategory
    /// Optional per-post accent override; falls back to the category color.
    var accent: Color? = nil

    private var color: Color { accent ?? category.color }

    var body: some View {
        Label {
            Text(category.shortLabel)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: category.systemImage)
                .font(.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
