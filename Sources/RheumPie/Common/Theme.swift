import SwiftUI

/// App-wide design tokens.
enum Theme {
    static let accentColor = Color("AccentColor")

    enum Font {
        static let articleTitle = SwiftUI.Font.title2.weight(.semibold)
        static let articleBody = SwiftUI.Font.body
        static let caption = SwiftUI.Font.caption
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
}
