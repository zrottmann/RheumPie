import SwiftUI
import AVFoundation

/// Full article reader presented as a sheet. Renders the shared
/// `ArticleReaderContent` (cover, styled title, Markdown body, accent, disclaimer)
/// and adds Read-Aloud + bookmark controls.
struct ReaderView: View {
    let article: Article
    @Environment(ArticleStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isSpeaking = false
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var delegate = SpeechDelegate()

    var body: some View {
        NavigationStack {
            ScrollView {
                ArticleReaderContent(article: article)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.top, Theme.Spacing.medium)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { stopSpeaking(); dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isSpeaking ? stopSpeaking() : startSpeaking()
                    } label: {
                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    }
                    .accessibilityLabel(isSpeaking ? "Stop reading aloud" : "Read aloud")

                    Button {
                        store.toggleBookmark(article)
                    } label: {
                        Image(systemName: store.isBookmarked(article) ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityLabel(store.isBookmarked(article) ? "Remove bookmark" : "Add bookmark")
                }
            }
        }
    }

    // MARK: - Read-aloud (AVSpeechSynthesizer)

    private func startSpeaking() {
        let text = "\(article.title). \(MarkdownParser.plainText(article.body))"
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        delegate.onFinish = { isSpeaking = false }
        synthesizer.delegate = delegate
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    private func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

// MARK: - Speech delegate

private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
