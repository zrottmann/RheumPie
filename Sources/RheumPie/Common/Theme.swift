import SwiftUI

/// App-wide design tokens.
enum Theme {
    static let accentColor = Color("AccentColor")

    enum Font {
        static let articleTitle = SwiftUI.Font.title3.weight(.semibold)
        static let articleBody = SwiftUI.Font.body
        static let caption = SwiftUI.Font.caption
        static let sectionHeader = SwiftUI.Font.subheadline.weight(.semibold)
    }

    enum Spacing {
        static let xsmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }

    enum Card {
        static let cornerRadius: CGFloat = 14
        static let shadowRadius: CGFloat = 6
        static let shadowOpacity: Double = 0.07
        static let accentBarHeight: CGFloat = 4
    }
}

// MARK: - Category color tokens

extension ArticleCategory {
    /// Thematic accent color, adaptive for light and dark mode.
    var color: Color {
        switch self {
        case .general: return .blue
        case .ra: return .red
        case .lupus: return .purple
        case .gout: return .orange
        case .psa: return .teal
        case .osteoarthritis: return .brown
        }
    }
}
