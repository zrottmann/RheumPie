import SwiftUI
import UIKit

/// A UITextView-backed editor that exposes the text **and the current selection**
/// so the formatting toolbar can insert/wrap Markdown at the cursor. SwiftUI's
/// iOS 17 `TextEditor` doesn't surface selection, hence this small UIKit bridge.
struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6)
        tv.autocapitalizationType = .sentences
        tv.adjustsFontForContentSizeCategory = true
        tv.keyboardDismissMode = .interactive
        tv.text = text
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
        let clamped = MDInsert.clamp(selection, (uiView.text as NSString).length)
        if uiView.selectedRange != clamped {
            uiView.selectedRange = clamped
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        init(_ parent: RichTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selection = textView.selectedRange
        }
        func textViewDidChangeSelection(_ textView: UITextView) {
            if parent.selection != textView.selectedRange {
                parent.selection = textView.selectedRange
            }
        }
    }
}

/// Pure string operations that wrap/insert Markdown relative to a selection.
/// Each returns the new text and the new selection so the caller can update both
/// bindings and the UITextView follows.
enum MDInsert {
    static func clamp(_ r: NSRange, _ len: Int) -> NSRange {
        let loc = min(max(0, r.location), len)
        let length = min(max(0, r.length), len - loc)
        return NSRange(location: loc, length: length)
    }

    /// Wraps the selection in `marker` (e.g. "**"); with no selection, inserts the
    /// markers and places the caret between them.
    static func wrap(_ text: String, _ range: NSRange, marker: String) -> (String, NSRange) {
        let ns = text as NSString
        let safe = clamp(range, ns.length)
        let m = (marker as NSString).length
        if safe.length == 0 {
            let newText = ns.replacingCharacters(in: safe, with: marker + marker)
            return (newText, NSRange(location: safe.location + m, length: 0))
        }
        let selected = ns.substring(with: safe)
        let newText = ns.replacingCharacters(in: safe, with: marker + selected + marker)
        return (newText, NSRange(location: safe.location + m, length: (selected as NSString).length))
    }

    /// Replaces the selection with `string`, caret after it.
    static func insert(_ text: String, _ range: NSRange, _ string: String) -> (String, NSRange) {
        let ns = text as NSString
        let safe = clamp(range, ns.length)
        let newText = ns.replacingCharacters(in: safe, with: string)
        return (newText, NSRange(location: safe.location + (string as NSString).length, length: 0))
    }

    /// Inserts a block (e.g. a divider or image) on its own lines at the caret.
    static func insertBlock(_ text: String, _ range: NSRange, _ block: String) -> (String, NSRange) {
        let ns = text as NSString
        let safe = clamp(range, ns.length)
        let before = safe.location > 0 ? ns.substring(with: NSRange(location: safe.location - 1, length: 1)) : "\n"
        let lead = before == "\n" ? "" : "\n\n"
        let payload = lead + block + "\n\n"
        let newText = ns.replacingCharacters(in: safe, with: payload)
        return (newText, NSRange(location: safe.location + (payload as NSString).length, length: 0))
    }

    /// Applies a per-line transform to every line the selection touches. Used for
    /// headings, quotes, and lists.
    static func transformLines(_ text: String, _ range: NSRange, _ transform: (Int, String) -> String) -> (String, NSRange) {
        let ns = text as NSString
        let safe = clamp(range, ns.length)
        let lineRange = ns.lineRange(for: safe)
        let block = ns.substring(with: lineRange)
        let trailingNL = block.hasSuffix("\n")
        var lines = block.components(separatedBy: "\n")
        if trailingNL { lines.removeLast() }
        let transformed = lines.enumerated().map { transform($0.offset, $0.element) }
        var newBlock = transformed.joined(separator: "\n")
        if trailingNL { newBlock += "\n" }
        let newText = ns.replacingCharacters(in: lineRange, with: newBlock)
        let newLen = (newBlock as NSString).length - (trailingNL ? 1 : 0)
        return (newText, NSRange(location: lineRange.location, length: max(0, newLen)))
    }

    /// Strips leading block markers (#, >, -, *, "N. ") so a new one can replace it.
    static func stripMarkers(_ line: String) -> String {
        var s = Substring(line)
        while s.first == " " { s = s.dropFirst() }
        while s.first == "#" { s = s.dropFirst() }
        if s.first == ">" { s = s.dropFirst() }
        if s.hasPrefix("- ") || s.hasPrefix("* ") { s = s.dropFirst(2) }
        // numbered "12. "
        var t = s
        var digits = 0
        while t.first?.isNumber == true { t = t.dropFirst(); digits += 1 }
        if digits > 0, t.first == ".", t.dropFirst().first == " " { s = t.dropFirst(2) }
        while s.first == " " { s = s.dropFirst() }
        return String(s)
    }
}
