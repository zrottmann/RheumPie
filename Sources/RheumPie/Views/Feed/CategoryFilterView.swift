import SwiftUI

/// Horizontal scroll of category filter chips.
struct CategoryFilterView: View {
    @Binding var selectedCategory: ArticleCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.small) {
                FilterChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ArticleCategory.allCases) { cat in
                    FilterChip(
                        label: cat.shortLabel,
                        systemImage: cat.systemImage,
                        selectedColor: cat.color,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
        }
    }
}

private struct FilterChip: View {
    let label: String
    var systemImage: String? = nil
    var selectedColor: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xsmall) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? selectedColor : Color(.systemGray5))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
