import SwiftUI

/// A parsed Markdown block. Intentionally small — covers exactly the formatting
/// the editor toolbar can produce (headings, lists, quotes, dividers, inline
/// images, and paragraphs with inline emphasis/links).
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullets([String])
    case numbered([String])
    case quote(String)
    case divider
    case image(name: String, alt: String)
}

/// Lightweight line-based Markdown parser. Not a full CommonMark implementation —
/// just enough for the authoring features, kept dependency-free.
enum MarkdownParser {
    static func parse(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        func flushParagraph() {
            let joined = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !joined.isEmpty { blocks.append(.paragraph(joined)) }
            paragraph.removeAll()
        }

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.isEmpty { flushParagraph(); i += 1; continue }

            if let img = parseImage(line) {
                flushParagraph(); blocks.append(.image(name: img.name, alt: img.alt)); i += 1; continue
            }
            if line == "---" || line == "***" || line == "___" {
                flushParagraph(); blocks.append(.divider); i += 1; continue
            }
            if line.hasPrefix("### ") {
                flushParagraph(); blocks.append(.heading(level: 3, text: String(line.dropFirst(4)))); i += 1; continue
            }
            if line.hasPrefix("## ") {
                flushParagraph(); blocks.append(.heading(level: 2, text: String(line.dropFirst(3)))); i += 1; continue
            }
            if line.hasPrefix("# ") {
                flushParagraph(); blocks.append(.heading(level: 1, text: String(line.dropFirst(2)))); i += 1; continue
            }
            if line.hasPrefix(">") {
                flushParagraph()
                var quote: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    guard l.hasPrefix(">") else { break }
                    quote.append(String(l.dropFirst()).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.quote(quote.joined(separator: " ")))
                continue
            }
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    guard l.hasPrefix("- ") || l.hasPrefix("* ") else { break }
                    items.append(String(l.dropFirst(2)))
                    i += 1
                }
                blocks.append(.bullets(items))
                continue
            }
            if let _ = numberedContent(line) {
                flushParagraph()
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    guard let item = numberedContent(l) else { break }
                    items.append(item)
                    i += 1
                }
                blocks.append(.numbered(items))
                continue
            }

            paragraph.append(line)
            i += 1
        }
        flushParagraph()
        return blocks
    }

    /// Renders inline emphasis (**bold**, *italic*) and [links](url).
    static func inline(_ s: String) -> AttributedString {
        (try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(s)
    }

    /// Markdown stripped to spoken-text for Read-Aloud (no markers, no images).
    static func plainText(_ md: String) -> String {
        var out: [String] = []
        for raw in md.components(separatedBy: "\n") {
            var line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if parseImage(line) != nil { continue }
            if line == "---" || line == "***" || line == "___" { continue }
            while line.hasPrefix("#") { line.removeFirst() }
            if line.hasPrefix(">") { line.removeFirst() }
            if line.hasPrefix("- ") || line.hasPrefix("* ") { line.removeFirst(2) }
            line = stripInline(line.trimmingCharacters(in: .whitespaces))
            if !line.isEmpty { out.append(line) }
        }
        return out.joined(separator: " ")
    }

    /// Removes inline emphasis markers and reduces [label](url) to "label".
    private static func stripInline(_ s: String) -> String {
        var t = s
        if let re = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^)]*\\)") {
            t = re.stringByReplacingMatches(
                in: t, range: NSRange(t.startIndex..., in: t), withTemplate: "$1")
        }
        for marker in ["**", "__", "*", "`", "_"] {
            t = t.replacingOccurrences(of: marker, with: "")
        }
        return t
    }

    private static func parseImage(_ line: String) -> (alt: String, name: String)? {
        guard line.hasPrefix("!["), line.hasSuffix(")"), let mid = line.range(of: "](") else { return nil }
        let alt = String(line[line.index(line.startIndex, offsetBy: 2)..<mid.lowerBound])
        let name = String(line[mid.upperBound..<line.index(before: line.endIndex)])
        return name.isEmpty ? nil : (alt, name)
    }

    private static func numberedContent(_ line: String) -> String? {
        guard let dot = line.firstIndex(of: ".") else { return nil }
        let num = line[line.startIndex..<dot]
        guard !num.isEmpty, num.allSatisfy(\.isNumber) else { return nil }
        let after = line[line.index(after: dot)...]
        guard after.first == " " else { return nil }
        return String(after.dropFirst())
    }
}

/// Renders a Markdown string as themed SwiftUI blocks. Shared by ReaderView and
/// the editor live preview so the author sees exactly the published layout.
struct MarkdownContentView: View {
    let markdown: String
    let accent: Color
    var bodyFont: Font = .body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(MarkdownParser.parse(markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(MarkdownParser.inline(text))
                .font(headingFont(level))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, level == 1 ? 6 : 2)

        case .paragraph(let text):
            Text(MarkdownParser.inline(text))
                .font(bodyFont)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

        case .bullets(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle().fill(accent).frame(width: 6, height: 6).padding(.top, 7)
                        Text(MarkdownParser.inline(item)).font(bodyFont).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .numbered(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(idx + 1).").font(bodyFont.weight(.semibold)).foregroundStyle(accent)
                        Text(MarkdownParser.inline(item)).font(bodyFont).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .quote(let text):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 4)
                Text(MarkdownParser.inline(text))
                    .font(bodyFont.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)

        case .divider:
            Rectangle().fill(accent.opacity(0.5)).frame(height: 2).padding(.vertical, 4)

        case .image(let name, let alt):
            if let ui = ImageStore.image(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel(alt.isEmpty ? "Image" : alt)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 160)
                    .overlay(Image(systemName: "photo").font(.title).foregroundStyle(.secondary))
            }
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title.weight(.bold)
        case 2: return .title2.weight(.bold)
        default: return .title3.weight(.semibold)
        }
    }
}
