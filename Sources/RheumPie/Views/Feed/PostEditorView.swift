import SwiftUI
import PhotosUI
import UIKit

/// Artist-grade composer for user-authored posts. Markdown rich text with a
/// formatting toolbar, a cover image, inline photos, PencilKit sketches, a
/// per-post accent color, title typography, and a live preview that renders
/// exactly as `ReaderView` will.
struct PostEditorView: View {
    @Environment(ArticleStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let editingArticle: Article?
    private let originalOwned: Set<String>

    @State private var title: String
    @State private var byline: String
    @State private var category: ArticleCategory
    @State private var summary: String
    @State private var bodyText: String
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var accent: Color
    @State private var accentCustom: Bool
    @State private var titleStyle: TitleStyle
    @State private var coverImageName: String?
    @State private var imageAttachmentNames: [String]

    @State private var addedThisSession: Set<String> = []
    @State private var mode: Mode = .edit
    @State private var showSketch = false
    @State private var coverItem: PhotosPickerItem?
    @State private var inlineItem: PhotosPickerItem?

    private enum Mode: String, CaseIterable { case edit = "Edit", preview = "Preview" }

    init(editing article: Article? = nil) {
        editingArticle = article
        let cat = article?.category ?? .general
        _title = State(initialValue: article?.title ?? "")
        _byline = State(initialValue: article?.byline ?? "Your Rheumatologist")
        _category = State(initialValue: cat)
        _summary = State(initialValue: article?.summary ?? "")
        _bodyText = State(initialValue: article?.body ?? "")
        _titleStyle = State(initialValue: article?.titleStyle ?? .standard)
        _coverImageName = State(initialValue: article?.coverImageName)
        _imageAttachmentNames = State(initialValue: article?.imageAttachmentNames ?? [])
        _accent = State(initialValue: article?.accentColor ?? cat.color)
        _accentCustom = State(initialValue: article?.accentColorHex != nil)
        originalOwned = Set((article?.coverImageName.map { [$0] } ?? []) + (article?.imageAttachmentNames ?? []))
    }

    private var isEditing: Bool { editingArticle != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// A transient article mirroring the current editor state, for live preview.
    private var draft: Article {
        Article(
            id: editingArticle?.id ?? "preview",
            title: title.isEmpty ? "Untitled" : title,
            byline: byline.isEmpty ? "Your Rheumatologist" : byline,
            publishDate: editingArticle?.publishDate ?? Date(),
            category: category,
            summary: summary,
            body: bodyText,
            isUserAuthored: true,
            coverImageName: coverImageName,
            accentColorHex: accentCustom ? accent.toHexString() : nil,
            titleStyle: titleStyle,
            imageAttachmentNames: imageAttachmentNames
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .edit: editForm
                case .preview: previewScroll
                }
            }
            .navigationTitle(isEditing ? "Edit Post" : "New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { cancel() }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .sheet(isPresented: $showSketch) {
                SketchCanvasView { image in insertSketch(image) }
            }
            .onChange(of: coverItem) { _, item in if let item { loadCover(item) } }
            .onChange(of: inlineItem) { _, item in if let item { loadInline(item) } }
        }
    }

    // MARK: - Edit form

    private var editForm: some View {
        Form {
            Section("Cover Image") {
                if let cover = coverImageName, let ui = ImageStore.image(named: cover) {
                    Image(uiImage: ui)
                        .resizable().scaledToFill()
                        .frame(height: 150).frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button(role: .destructive) { removeCover() } label: {
                        Label("Remove Cover", systemImage: "trash")
                    }
                }
                PhotosPicker(selection: $coverItem, matching: .images, photoLibrary: .shared()) {
                    Label(coverImageName == nil ? "Choose Cover" : "Replace Cover", systemImage: "photo")
                }
            }

            Section("Title") {
                TextField("Article title", text: $title)
                    .font(.title3.weight(.semibold))
                    .fontDesign(titleStyle.fontDesign)
                Picker("Typography", selection: $titleStyle) {
                    ForEach(TitleStyle.allCases) { Text($0.rawValue).fontDesign($0.fontDesign).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Appearance") {
                ColorPicker("Accent Color", selection: accentBinding, supportsOpacity: false)
                if accentCustom {
                    Button { resetAccent() } label: {
                        Label("Use Category Color", systemImage: "arrow.uturn.backward")
                    }
                }
            }

            Section("Category") {
                Picker("Category", selection: categoryBinding) {
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
                formattingBar
                RichTextEditor(text: $bodyText, selection: $selection)
                    .frame(minHeight: 280)
            } header: {
                Text("Body")
            } footer: {
                Text("Formatting buttons insert Markdown. Separate paragraphs with a blank line.")
            }
        }
    }

    // MARK: - Formatting toolbar

    private var formattingBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                fmtButton("textformat.size.larger", "Heading 1") { applyHeading(1) }
                fmtButton("textformat.size", "Heading 2") { applyHeading(2) }
                fmtButton("textformat.size.smaller", "Heading 3") { applyHeading(3) }
                Divider().frame(height: 24)
                fmtButton("bold", "Bold") { apply { MDInsert.wrap($0, $1, marker: "**") } }
                fmtButton("italic", "Italic") { apply { MDInsert.wrap($0, $1, marker: "*") } }
                Divider().frame(height: 24)
                fmtButton("list.bullet", "Bulleted list") { applyLinePrefix { _ in "- " } }
                fmtButton("list.number", "Numbered list") { applyLinePrefix { "\($0 + 1). " } }
                fmtButton("text.quote", "Quote") { applyLinePrefix { _ in "> " } }
                fmtButton("minus", "Divider") { apply { MDInsert.insertBlock($0, $1, "---") } }
                fmtButton("link", "Link") { insertLink() }
                Divider().frame(height: 24)
                PhotosPicker(selection: $inlineItem, matching: .images, photoLibrary: .shared()) {
                    barIcon("photo.badge.plus")
                }
                fmtButton("scribble.variable", "Sketch") { showSketch = true }
            }
            .padding(.vertical, 4)
        }
    }

    private func fmtButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { barIcon(icon) }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
    }

    private func barIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .frame(width: 38, height: 32)
            .background(Color(.systemGray5))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    // MARK: - Preview

    private var previewScroll: some View {
        ScrollView {
            ArticleReaderContent(article: draft)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.top, Theme.Spacing.medium)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Bindings

    private var categoryBinding: Binding<ArticleCategory> {
        Binding(get: { category }, set: { newValue in
            category = newValue
            if !accentCustom { accent = newValue.color }
        })
    }

    private var accentBinding: Binding<Color> {
        Binding(get: { accent }, set: { newValue in
            accent = newValue
            accentCustom = true
        })
    }

    private func resetAccent() {
        accentCustom = false
        accent = category.color
    }

    // MARK: - Body editing actions

    private func apply(_ transform: (String, NSRange) -> (String, NSRange)) {
        let (t, s) = transform(bodyText, selection)
        bodyText = t
        selection = s
    }

    private func applyHeading(_ level: Int) {
        let prefix = String(repeating: "#", count: level) + " "
        apply { MDInsert.transformLines($0, $1) { _, line in prefix + MDInsert.stripMarkers(line) } }
    }

    private func applyLinePrefix(_ prefix: @escaping (Int) -> String) {
        apply { MDInsert.transformLines($0, $1) { idx, line in prefix(idx) + MDInsert.stripMarkers(line) } }
    }

    private func insertLink() {
        let ns = bodyText as NSString
        let safe = MDInsert.clamp(selection, ns.length)
        let label = safe.length > 0 ? ns.substring(with: safe) : "link text"
        let md = "[\(label)](https://)"
        let (t, _) = MDInsert.insert(bodyText, safe, md)
        bodyText = t
        let urlStart = safe.location + ("[\(label)](" as NSString).length
        selection = NSRange(location: urlStart, length: ("https://" as NSString).length)
    }

    private func insertSketch(_ image: UIImage) {
        guard let name = ImageStore.saveSketch(image) else { return }
        imageAttachmentNames.append(name)
        addedThisSession.insert(name)
        apply { MDInsert.insertBlock($0, $1, "![sketch](\(name))") }
    }

    // MARK: - Image picker side effects

    private func loadCover(_ item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let name = ImageStore.savePhoto(uiImage) else { return }
            await MainActor.run {
                if let old = coverImageName, addedThisSession.contains(old) {
                    ImageStore.delete(named: old); addedThisSession.remove(old)
                }
                coverImageName = name
                addedThisSession.insert(name)
                coverItem = nil
            }
        }
    }

    private func loadInline(_ item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let name = ImageStore.savePhoto(uiImage) else { return }
            await MainActor.run {
                imageAttachmentNames.append(name)
                addedThisSession.insert(name)
                apply { MDInsert.insertBlock($0, $1, "![photo](\(name))") }
                inlineItem = nil
            }
        }
    }

    private func removeCover() {
        if let old = coverImageName, addedThisSession.contains(old) {
            ImageStore.delete(named: old); addedThisSession.remove(old)
        }
        coverImageName = nil
    }

    // MARK: - Persist / discard

    private func save() {
        let finalHex: String? = {
            guard accentCustom, let hex = accent.toHexString() else { return nil }
            if hex.caseInsensitiveCompare(category.color.toHexString() ?? "") == .orderedSame { return nil }
            return hex
        }()
        let t = title.trimmingCharacters(in: .whitespaces)
        let b = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = summary.trimmingCharacters(in: .whitespaces)
        let by = byline.trimmingCharacters(in: .whitespaces)

        if let existing = editingArticle {
            let updated = Article(
                id: existing.id, title: t,
                byline: by.isEmpty ? "Your Rheumatologist" : by,
                publishDate: existing.publishDate, category: category,
                summary: s, body: b, isUserAuthored: true,
                coverImageName: coverImageName, accentColorHex: finalHex,
                titleStyle: titleStyle, imageAttachmentNames: imageAttachmentNames
            )
            store.updatePost(updated)
        } else {
            store.createPost(
                title: t, category: category, summary: s, body: b, byline: by,
                coverImageName: coverImageName, accentColorHex: finalHex,
                titleStyle: titleStyle, imageAttachmentNames: imageAttachmentNames
            )
        }
        dismiss()
    }

    private func cancel() {
        // Discard images added this session that the saved article never owned.
        ImageStore.delete(names: Array(addedThisSession.subtracting(originalOwned)))
        dismiss()
    }
}
