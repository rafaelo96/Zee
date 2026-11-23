import SwiftUI

/// What the note's formatting bar asks of the editor that has the text: the
/// selection to wrap or the lines to mark. The editor registers itself here
/// when it appears, so the bar never holds a view.
@MainActor
@Observable
final class BrowserNoteEditorController {
    // MARK: - Types

    enum LineFormat {
        case heading
        case bullet
        case checklist
        case numbered
    }

    enum InlineFormat {
        case bold
        case italic
        case code
    }

    // MARK: - Variables

    @ObservationIgnored var applyLine: ((LineFormat) -> Void)?
    @ObservationIgnored var applyInline: ((InlineFormat) -> Void)?
    @ObservationIgnored var applyLink: (() -> Void)?
    @ObservationIgnored var focusEditor: (() -> Void)?

    // MARK: - Actions

    func format(_ format: LineFormat) { applyLine?(format) }
    func format(_ format: InlineFormat) { applyInline?(format) }
    func insertLink() { applyLink?() }
    func focus() { focusEditor?() }
}
