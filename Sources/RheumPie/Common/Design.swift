import SwiftUI
import UIKit

// MARK: - Per-post accent color

extension Article {
    /// The article's effective accent color: the author's per-post override when
    /// set, otherwise the category color.
    var accentColor: Color {
        if let hex = accentColorHex, let c = Color(hex: hex) { return c }
        return category.color
    }
}

// MARK: - Title typography → SwiftUI font design

extension TitleStyle {
    var fontDesign: Font.Design {
        switch self {
        case .standard: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

// MARK: - Color <-> hex

extension Color {
    /// Parses "#RRGGBB" (or "RRGGBB"). Returns nil on malformed input.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255.0,
            green: Double((v >> 8) & 0xFF) / 255.0,
            blue: Double(v & 0xFF) / 255.0
        )
    }

    /// Serializes to "#RRGGBB" via UIColor resolution. Nil if not resolvable.
    func toHexString() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(
            format: "#%02X%02X%02X",
            Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())
        )
    }
}
