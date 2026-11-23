import SwiftUI

/// A note as its tab shows it: a title, a bar of formats, and the text under
/// it, on Zee's paper, kept as the person writes. Each pause in typing saves
/// the note through the core, which names the tab by it; leaving the tab
/// saves what is left. The text is Markdown, which the Mac's editor styles as
/// it is written.
struct BrowserNoteTabView: View {
    let note: Note
    let save: (_ title: String, _ body: String) -> Void
    var openLink: (URL) -> Void = { _ in }
    var delete: (() -> Void)?

    @State private var title: String
    @State private var text: String
    @State private var editor = BrowserNoteEditorController()
    @State private var isConfirmingDelete = false
    @FocusState private var isTitleFocused: Bool

    init(
        note: Note, save: @escaping (_ title: String, _ body: String) -> Void,
        openLink: @escaping (URL) -> Void = { _ in }, delete: (() -> Void)? = nil
    ) {
        self.note = note
        self.save = save
        self.openLink = openLink
        self.delete = delete
        _title = State(initialValue: note.title)
        _text = State(initialValue: note.body)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ZeeSpacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: ZeeSpacing.small) {
                TextField("Title", text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(ZeeTypography.display(BrowserNoteTabMetrics.titleSize))
                    .foregroundStyle(ZeeBrandTheme.textDisplay)
                    .focused($isTitleFocused)
                    .onSubmit { editor.focus() }
                    .accessibilityIdentifier("note-title-field")
                noteMenu
            }

            BrowserNoteFormatBar(editor: editor)

            bodyEditor
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: BrowserNoteTabMetrics.columnWidth, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, ZeeSpacing.screen)
        .padding(.top, ZeeSpacing.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ZeeBrandTheme.canvas)
        // A pause in typing saves; the task restarts with every keystroke.
        .task(id: Draft(title: title, body: text)) {
            try? await Task.sleep(for: BrowserNoteTabMetrics.saveDelay)
            guard !Task.isCancelled else { return }
            saveIfChanged()
        }
        .onDisappear(perform: saveIfChanged)
        .onAppear { if note.title.isEmpty && note.body.isEmpty { isTitleFocused = true } }
        .confirmationDialog(
            "Delete this note?", isPresented: $isConfirmingDelete, titleVisibility: .visible
        ) {
            Button("Delete Note", role: .destructive) { delete?() }
        } message: {
            Text("The note is deleted on every device that syncs this Space. This can’t be undone.")
        }
    }

    @ViewBuilder
    private var bodyEditor: some View {
        #if os(macOS)
            BrowserNoteMarkdownEditor(text: $text, controller: editor, openLink: openLink)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Start writing…")
                            .font(ZeeTypography.sans(BrowserNoteTabMetrics.bodySize))
                            .foregroundStyle(ZeeBrandTheme.textSecondary)
                            .allowsHitTesting(false)
                    }
                }
        #else
            TextEditor(text: $text)
                .font(ZeeTypography.sans(BrowserNoteTabMetrics.bodySize))
                .foregroundStyle(ZeeBrandTheme.textDisplay)
                .scrollContentBackground(.hidden)
                .accessibilityIdentifier("note-body-editor")
        #endif
    }

    @ViewBuilder
    private var noteMenu: some View {
        if delete != nil {
            Menu {
                Group {
                    Button("Delete Note…", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                }
                .zeeMenuActionLabelStyle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            #if os(macOS)
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            #endif
            .fixedSize()
            .tint(.secondary)
            .help("Note Actions")
            .accessibilityLabel("Note actions")
        }
    }

    private func saveIfChanged() {
        guard title != note.title || text != note.body else { return }
        save(title, text)
    }

    private struct Draft: Equatable {
        let title: String
        let body: String
    }
}

/// The formats a note offers, each a button that marks the selected lines or
/// wraps the selected words in the Markdown it stands for.
struct BrowserNoteFormatBar: View {
    let editor: BrowserNoteEditorController

    var body: some View {
        HStack(spacing: ZeeSpacing.extraExtraSmall) {
            button("Heading", "textformat.size") { editor.format(.heading) }
            button("Bold (⌘B)", "bold") { editor.format(.bold) }
            button("Italic (⌘I)", "italic") { editor.format(.italic) }
            button("Code", "chevron.left.forwardslash.chevron.right") { editor.format(.code) }
            Divider().frame(height: BrowserNoteTabMetrics.formatDividerHeight)
            button("Bulleted List", "list.bullet") { editor.format(.bullet) }
            button("Numbered List", "list.number") { editor.format(.numbered) }
            button("Checklist", "checklist") { editor.format(.checklist) }
            Divider().frame(height: BrowserNoteTabMetrics.formatDividerHeight)
            button("Link (⌘K)", "link") { editor.insertLink() }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(ZeeChromeButtonStyle())
        .foregroundStyle(ZeeBrandTheme.textSecondary)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Formatting")
    }

    private func button(_ title: LocalizedStringKey, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(title, systemImage: symbol, action: action)
            .help(title)
    }
}

enum BrowserNoteTabMetrics {
    static let titleSize: CGFloat = 32
    static let bodySize: CGFloat = 16
    static let lineSpacing: CGFloat = 4
    static let columnWidth: CGFloat = 720
    static let formatDividerHeight: CGFloat = 16
    /// How long typing rests before the note is saved.
    static let saveDelay: Duration = .milliseconds(600)
}

#if DEBUG
    #Preview("Note") {
        BrowserNoteTabView(
            note: Note(
                id: UUID(), title: "Trip",
                body: "# Packing\n- [x] Charger\n- [ ] Passport\n\nBook the **train** at [Renfe](https://renfe.com)",
                modifiedAt: .now),
            save: { _, _ in }, delete: {}
        )
        .frame(width: 900, height: 600)
    }
#endif
