import SwiftUI

/// Settings / About screen. Shows app version per standing rule.
struct SettingsView: View {
    @Environment(ArticleStore.self) private var store

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("App", value: "Rheum Pie")
                    LabeledContent("Version", value: "\(appVersion) (\(buildNumber))")
                    LabeledContent("Articles", value: "\(store.articles.count)")
                    LabeledContent("Bookmarks", value: "\(store.bookmarkedArticles.count)")
                }

                Section("Medical Disclaimer") {
                    Text("Rheum Pie provides patient education articles written by a rheumatologist. The content is for informational purposes only and does not constitute medical advice. Always consult your rheumatologist or healthcare provider regarding your individual treatment.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Text("Rheum Pie is fully offline. No data leaves your device. Bookmarks are stored only in your device's local storage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
