import SwiftUI

/// Sheet editor for creating or updating a user-authored post.
///
/// Pass `editing: nil` to create a new post, or an existing `Article`
/// (that `isUserAuthored == true`) to edit it.
struct PostEditorView: View {
    @Environment(ArticleStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let editingArticle: Article?

    @State private var title: String
    @State private var byline: String
    @State private var category: ArticleCategory
    @State private var summary: String
    @State private var bodyText: String

    init(editing article: Article? = nil) {
        editingArticle = article
        _title = State(initialValue: article?.title ?? "")
        _byline = State(initialValue: article?.byline ?? "Your Rheumatologist")
        _category = State(initialValue: article?.category ?? .general)
        _summary = State(initialValue: article?.summary ?? "")
        _bodyText = State(initialValue: article?.body ?? "")
    }

    private var isEditing: Bool { editingArticle != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Article title", text: $title)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ArticleCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.systemImage).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Summary") {
                    TextField("A brief summary or dek", text: $summary, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Byline") {
                    TextField("Author name", text: $byline)
                }

                Section {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                        .font(.body)
                } header: {
                    Text("Body")
                } footer: {
                    Text("Separate paragraphs with a blank line.")
                }
            }
            .navigationTitle(isEditing ? "Edit Post" : "New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        let b = bodyText.trimmingCharacters(in: .whitespaces)
        let s = summary.trimmingCharacters(in: .whitespaces)
        let by = byline.trimmingCharacters(in: .whitespaces)

        if let existing = editingArticle {
            let updated = Article(
                id: existing.id,
                title: t,
                byline: by.isEmpty ? "Your Rheumatologist" : by,
                publishDate: existing.publishDate,
                category: category,
                summary: s,
                body: b,
                isUserAuthored: true
            )
            store.updatePost(updated)
        } else {
            store.createPost(title: t, category: category, summary: s, body: b, byline: by)
        }
        dismiss()
    }
}
