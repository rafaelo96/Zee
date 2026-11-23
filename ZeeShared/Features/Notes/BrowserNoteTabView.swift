import SwiftUI

/// A note as its tab shows it: a title and the text under it, on Zee's paper,
/// kept as the person writes. Each pause in typing saves the note through the
/// core, which names the tab by it; leaving the tab saves what is left.
struct BrowserNoteTabView: View {
    let note: Note
    let save: (_ title: String, _ body: String) -> Void

    @State private var title: String
    @State private var text: String
    @FocusState private var focus: Field?

    private enum Field { case title, body }

    init(note: Note, save: @escaping (_ title: String, _ body: String) -> Void) {
        self.note = note
        self.save = save
        _title = State(initialValue: note.title)
        _text = State(initialValue: note.body)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ZeeSpacing.medium) {
                TextField("Title", text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(ZeeTypography.display(BrowserNoteTabMetrics.titleSize))
                    .foregroundStyle(ZeeBrandTheme.textDisplay)
                    .focused($focus, equals: .title)
                    .onSubmit { focus = .body }
                    .accessibilityIdentifier("note-title-field")

                TextEditor(text: $text)
                    .font(ZeeTypography.sans(BrowserNoteTabMetrics.bodySize))
                    .foregroundStyle(ZeeBrandTheme.textDisplay)
                    .lineSpacing(BrowserNoteTabMetrics.lineSpacing)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .frame(minHeight: BrowserNoteTabMetrics.minimumBodyHeight, alignment: .topLeading)
                    .focused($focus, equals: .body)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Start writing…")
                                .font(ZeeTypography.sans(BrowserNoteTabMetrics.bodySize))
                                .foregroundStyle(ZeeBrandTheme.textSecondary)
                                .padding(.leading, BrowserNoteTabMetrics.placeholderInset)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityIdentifier("note-body-editor")
            }
            .frame(maxWidth: BrowserNoteTabMetrics.columnWidth, alignment: .leading)
            .padding(.horizontal, ZeeSpacing.screen)
            .padding(.vertical, ZeeSpacing.section)
            .frame(maxWidth: .infinity)
        }
        .background(ZeeBrandTheme.canvas)
        // A pause in typing saves; the task restarts with every keystroke.
        .task(id: Draft(title: title, body: text)) {
            try? await Task.sleep(for: BrowserNoteTabMetrics.saveDelay)
            guard !Task.isCancelled else { return }
            saveIfChanged()
        }
        .onDisappear(perform: saveIfChanged)
        .onAppear { if note.title.isEmpty && note.body.isEmpty { focus = .title } }
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

enum BrowserNoteTabMetrics {
    static let titleSize: CGFloat = 32
    static let bodySize: CGFloat = 16
    static let lineSpacing: CGFloat = 4
    static let columnWidth: CGFloat = 720
    static let minimumBodyHeight: CGFloat = 320
    /// Where the editor draws its first character, so the placeholder sits on it.
    static let placeholderInset: CGFloat = 5
    /// How long typing rests before the note is saved.
    static let saveDelay: Duration = .milliseconds(600)
}

#if DEBUG
    #Preview("Note") {
        BrowserNoteTabView(
            note: Note(id: UUID(), title: "Trip", body: "Pack the charger\nBook the train", modifiedAt: .now),
            save: { _, _ in }
        )
        .frame(width: 900, height: 600)
    }
#endif
