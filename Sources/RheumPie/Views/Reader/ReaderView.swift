import SwiftUI
import AVFoundation

/// Full article reader presented as a sheet.
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
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    // Category + meta row
                    HStack {
                        Label(article.category.rawValue, systemImage: article.category.systemImage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Label("\(article.estimatedReadMinutes) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Title
                    Text(article.title)
                        .font(.largeTitle.weight(.bold))

                    // Byline + date
                    HStack {
                        Text(article.byline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(article.publishDate, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    // Body paragraphs — split on double newline
                    let paragraphs = article.body
                        .components(separatedBy: "\n\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                        Text(para)
                            .font(.body)
                            .lineSpacing(6)
                    }

                    // Disclaimer
                    DisclaimerView()
                        .padding(.top, Theme.Spacing.small)
                }
                .padding(Theme.Spacing.medium)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { stopSpeaking(); dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Read-aloud toggle
                    Button {
                        isSpeaking ? stopSpeaking() : startSpeaking()
                    } label: {
                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    }
                    .accessibilityLabel(isSpeaking ? "Stop reading aloud" : "Read aloud")

                    // Bookmark
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
        let text = "\(article.title). \(article.body)"
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

// MARK: - Disclaimer

private struct DisclaimerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("This article is for patient education only and is not a substitute for professional medical advice. Always talk to your rheumatologist before making any changes to your treatment.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.medium)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
