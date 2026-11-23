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

    @ObservationIgnored fileprivate var applyLine: ((LineFormat) -> Void)?
    @ObservationIgnored fileprivate var applyInline: ((InlineFormat) -> Void)?
    @ObservationIgnored fileprivate var applyLink: (() -> Void)?
    @ObservationIgnored fileprivate var focusEditor: (() -> Void)?

    // MARK: - Actions

    func format(_ format: LineFormat) { applyLine?(format) }
    func format(_ format: InlineFormat) { applyInline?(format) }
    func insertLink() { applyLink?() }
    func focus() { focusEditor?() }
}

#if os(macOS)
    import AppKit

    /// A note's text as Markdown, styled as it is written: headings larger,
    /// lists hung from their markers, checklist boxes a click toggles,
    /// emphasis and code drawn as they read, and links that open in a new
    /// tab of the note's Space. The markers stay in the text, faded, so what
    /// syncs is the plain Markdown the person sees.
    struct BrowserNoteMarkdownEditor: NSViewRepresentable {
        @Binding var text: String
        let controller: BrowserNoteEditorController
        let openLink: (URL) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text, openLink: openLink)
        }

        func makeNSView(context: Context) -> NSScrollView {
            let textView = BrowserNoteTextView()
            textView.delegate = context.coordinator
            textView.textStorage?.delegate = context.coordinator
            textView.isRichText = false
            textView.allowsUndo = true
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticLinkDetectionEnabled = false
            textView.drawsBackground = false
            textView.textContainerInset = .zero
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]
            textView.font = BrowserNoteEditorStyle.bodyFont
            textView.typingAttributes = BrowserNoteEditorStyle.bodyAttributes
            textView.linkTextAttributes = [.foregroundColor: NSColor.controlAccentColor, .cursor: NSCursor.pointingHand]
            textView.setAccessibilityIdentifier("note-body-editor")
            textView.string = text
            context.coordinator.textView = textView
            context.coordinator.restyle()
            context.coordinator.connect(controller)

            let scroll = NSScrollView()
            scroll.drawsBackground = false
            scroll.hasVerticalScroller = true
            scroll.autohidesScrollers = true
            scroll.documentView = textView
            textView.frame = NSRect(origin: .zero, size: scroll.contentSize)
            textView.minSize = NSSize(width: 0, height: scroll.contentSize.height)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            return scroll
        }

        func updateNSView(_ scroll: NSScrollView, context: Context) {
            context.coordinator.text = $text
            context.coordinator.openLink = openLink
            guard let textView = context.coordinator.textView, textView.string != text else { return }
            textView.string = text
            context.coordinator.restyle()
        }

        // MARK: - Coordinator

        @MainActor
        final class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
            var text: Binding<String>
            var openLink: (URL) -> Void
            weak var textView: BrowserNoteTextView?
            private var isRestyling = false

            init(text: Binding<String>, openLink: @escaping (URL) -> Void) {
                self.text = text
                self.openLink = openLink
            }

            func connect(_ controller: BrowserNoteEditorController) {
                controller.applyLine = { [weak self] format in self?.toggle(format) }
                controller.applyInline = { [weak self] format in self?.wrap(format) }
                controller.applyLink = { [weak self] in self?.insertLink() }
                controller.focusEditor = { [weak self] in
                    guard let textView = self?.textView else { return }
                    textView.window?.makeFirstResponder(textView)
                }
                textView?.toggleChecklist = { [weak self] location in self?.toggleChecklist(at: location) ?? false }
                textView?.shortcut = { [weak self] key in
                    switch key {
                    case "b": self?.wrap(.bold)
                    case "i": self?.wrap(.italic)
                    case "k": self?.insertLink()
                    default: return false
                    }
                    return true
                }
            }

            // MARK: Editing

            func textDidChange(_ notification: Notification) {
                guard let textView else { return }
                text.wrappedValue = textView.string
            }

            nonisolated func textStorage(
                _ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions,
                range editedRange: NSRange, changeInLength delta: Int
            ) {
                guard editedMask.contains(.editedCharacters) else { return }
                MainActor.assumeIsolated {
                    // Styling happens after the edit settles, outside the
                    // storage's own processing.
                    DispatchQueue.main.async { [weak self] in self?.restyle() }
                }
            }

            func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
                guard let url = (link as? URL) ?? (link as? String).flatMap(URL.init(string:)) else { return false }
                openLink(url)
                return true
            }

            /// Return carries a list on, and ends it on an empty item.
            func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
                guard selector == #selector(NSResponder.insertNewline(_:)) else { return false }
                let string = textView.string as NSString
                let selection = textView.selectedRange()
                let lineRange = string.lineRange(for: NSRange(location: selection.location, length: 0))
                let line = string.substring(with: lineRange).trimmingCharacters(in: .newlines)
                guard let marker = BrowserNoteMarkdown.continuation(of: line) else { return false }
                if BrowserNoteMarkdown.isEmptyListItem(line) {
                    let contentRange = NSRange(location: lineRange.location, length: (line as NSString).length)
                    replace(contentRange, with: "")
                    return true
                }
                replace(selection, with: "\n" + marker)
                return true
            }

            // MARK: Formatting

            private func toggle(_ format: BrowserNoteEditorController.LineFormat) {
                guard let textView else { return }
                let string = textView.string as NSString
                let lines = string.lineRange(for: textView.selectedRange())
                var edited: [String] = []
                string.enumerateSubstrings(in: lines, options: [.byLines, .substringNotRequired]) { _, range, _, _ in
                    edited.append(string.substring(with: range))
                }
                if edited.isEmpty { edited = [""] }
                let marker: String =
                    switch format {
                    case .heading: "# "
                    case .bullet: "- "
                    case .checklist: "- [ ] "
                    case .numbered: "1. "
                    }
                let allHave = edited.allSatisfy { $0.hasPrefix(marker) }
                let result = edited.enumerated().map { index, line in
                    let bare = String(line.dropFirst(BrowserNoteMarkdown.markerLength(of: line)))
                    if allHave { return bare }
                    return format == .numbered ? "\(index + 1). " + bare : marker + bare
                }.joined(separator: "\n")
                let trailing = string.substring(with: lines).hasSuffix("\n") ? "\n" : ""
                replace(lines, with: result + trailing)
                focus()
            }

            private func wrap(_ format: BrowserNoteEditorController.InlineFormat) {
                guard let textView else { return }
                let marker: String =
                    switch format {
                    case .bold: "**"
                    case .italic: "*"
                    case .code: "`"
                    }
                let selection = textView.selectedRange()
                let selected = (textView.string as NSString).substring(with: selection)
                if selected.hasPrefix(marker), selected.hasSuffix(marker), selected.count >= marker.count * 2 {
                    replace(selection, with: String(selected.dropFirst(marker.count).dropLast(marker.count)))
                } else {
                    replace(selection, with: marker + selected + marker)
                    if selection.length == 0 {
                        textView.setSelectedRange(NSRange(location: selection.location + marker.utf16.count, length: 0))
                    }
                }
                focus()
            }

            private func insertLink() {
                guard let textView else { return }
                let selection = textView.selectedRange()
                let selected = (textView.string as NSString).substring(with: selection)
                let label = selected.isEmpty ? String(localized: "link") : selected
                replace(selection, with: "[\(label)](https://)")
                // The address waits to be typed.
                let address = selection.location + ("[\(label)](" as NSString).length
                textView.setSelectedRange(NSRange(location: address, length: ("https://" as NSString).length))
                focus()
            }

            /// Toggles the checklist box at `location`, if there is one there.
            private func toggleChecklist(at location: Int) -> Bool {
                guard let textView else { return false }
                let string = textView.string as NSString
                guard location <= string.length else { return false }
                let lineRange = string.lineRange(for: NSRange(location: location, length: 0))
                let line = string.substring(with: lineRange)
                guard case .checklist(let isDone, _, let box) = BrowserNoteMarkdown.classify(line),
                    (lineRange.location + box.lowerBound)..<(lineRange.location + box.upperBound) ~= location
                else { return false }
                let mark = NSRange(location: lineRange.location + box.lowerBound + 1, length: 1)
                replace(mark, with: isDone ? " " : "x")
                return true
            }

            /// Replaces `range` with `string` as one undoable edit the text
            /// view knows of, so undo and the binding both follow.
            private func replace(_ range: NSRange, with string: String) {
                guard let textView, textView.shouldChangeText(in: range, replacementString: string) else { return }
                textView.textStorage?.replaceCharacters(in: range, with: string)
                textView.didChangeText()
                if range.length > 0 || !string.isEmpty {
                    let end = range.location + (string as NSString).length
                    if textView.selectedRange().location > end { textView.setSelectedRange(NSRange(location: end, length: 0)) }
                }
            }

            private func focus() {
                guard let textView else { return }
                textView.window?.makeFirstResponder(textView)
            }

            // MARK: Styling

            func restyle() {
                guard !isRestyling, let textView, let storage = textView.textStorage else { return }
                isRestyling = true
                defer { isRestyling = false }
                let string = storage.string as NSString
                storage.beginEditing()
                storage.setAttributes(
                    BrowserNoteEditorStyle.bodyAttributes, range: NSRange(location: 0, length: string.length))
                string.enumerateSubstrings(
                    in: NSRange(location: 0, length: string.length), options: [.byLines]
                ) { line, range, _, _ in
                    guard let line else { return }
                    BrowserNoteEditorStyle.style(line: line, at: range.location, in: storage)
                }
                storage.endEditing()
                textView.typingAttributes = BrowserNoteEditorStyle.bodyAttributes
            }
        }
    }

    /// The note's text view: a click on a checklist box toggles it, and the
    /// formatting keys reach the note before the menu bar.
    final class BrowserNoteTextView: NSTextView {
        var toggleChecklist: ((Int) -> Bool)?
        var shortcut: ((String) -> Bool)?

        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            let index = characterIndexForInsertion(at: point)
            if let toggleChecklist, toggleChecklist(index) || (index > 0 && toggleChecklist(index - 1)) { return }
            super.mouseDown(with: event)
        }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if window?.firstResponder === self,
                event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                let key = event.charactersIgnoringModifiers?.lowercased(), let shortcut, shortcut(key)
            {
                return true
            }
            return super.performKeyEquivalent(with: event)
        }
    }

    /// How a note's Markdown is drawn on the Mac.
    @MainActor
    enum BrowserNoteEditorStyle {
        static let bodySize: CGFloat = BrowserNoteTabMetrics.bodySize
        static let bodyFont = NSFont.systemFont(ofSize: bodySize)
        static let listIndent: CGFloat = 22

        static var bodyParagraph: NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = BrowserNoteTabMetrics.lineSpacing
            style.paragraphSpacing = 4
            return style
        }

        static var bodyAttributes: [NSAttributedString.Key: Any] {
            [.font: bodyFont, .foregroundColor: NSColor.labelColor, .paragraphStyle: bodyParagraph]
        }

        private static let markerColor = NSColor.tertiaryLabelColor
        private static let headingSizes: [CGFloat] = [26, 21, 18]

        static func style(line: String, at offset: Int, in storage: NSTextStorage) {
            let length = (line as NSString).length
            let whole = NSRange(location: offset, length: length)
            func marker(_ count: Int) -> NSRange { NSRange(location: offset, length: min(count, length)) }

            switch BrowserNoteMarkdown.classify(line) {
            case .heading(let level, let markerLength):
                let size = headingSizes[min(level, headingSizes.count) - 1]
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: size, weight: .bold), range: whole)
                let paragraph = bodyParagraph.mutableCopy() as! NSMutableParagraphStyle
                paragraph.paragraphSpacingBefore = 8
                storage.addAttribute(.paragraphStyle, value: paragraph, range: whole)
                storage.addAttribute(.foregroundColor, value: markerColor, range: marker(markerLength))
            case .bullet(let markerLength), .numbered(let markerLength):
                storage.addAttribute(.paragraphStyle, value: hanging(markerLength, line: line), range: whole)
                storage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: marker(markerLength))
            case .checklist(let isDone, let markerLength, let box):
                storage.addAttribute(.paragraphStyle, value: hanging(markerLength, line: line), range: whole)
                storage.addAttribute(.foregroundColor, value: markerColor, range: marker(box.lowerBound))
                let boxRange = NSRange(location: offset + box.lowerBound, length: box.count)
                storage.addAttributes(
                    [
                        .foregroundColor: NSColor.controlAccentColor,
                        .font: NSFont.monospacedSystemFont(ofSize: bodySize, weight: .semibold),
                        .cursor: NSCursor.pointingHand,
                    ], range: boxRange)
                if isDone, length > markerLength {
                    let content = NSRange(location: offset + markerLength, length: length - markerLength)
                    storage.addAttributes(
                        [.foregroundColor: NSColor.secondaryLabelColor, .strikethroughStyle: NSUnderlineStyle.single.rawValue],
                        range: content)
                }
            case .quote(let markerLength):
                storage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: whole)
                storage.addAttribute(.foregroundColor, value: markerColor, range: marker(markerLength))
            case .body:
                break
            }

            for span in BrowserNoteMarkdown.inlines(in: line) {
                let range = NSRange(location: offset + span.range.location, length: span.range.length)
                let content = NSRange(location: offset + span.content.location, length: span.content.length)
                let current = storage.attribute(.font, at: content.location, effectiveRange: nil) as? NSFont ?? bodyFont
                switch span.kind {
                case .bold:
                    storage.addAttribute(.font, value: NSFontManager.shared.convert(current, toHaveTrait: .boldFontMask), range: content)
                case .italic:
                    storage.addAttribute(.font, value: NSFontManager.shared.convert(current, toHaveTrait: .italicFontMask), range: content)
                case .code:
                    storage.addAttributes(
                        [
                            .font: NSFont.monospacedSystemFont(ofSize: current.pointSize * 0.92, weight: .regular),
                            .backgroundColor: NSColor.quaternaryLabelColor,
                        ], range: content)
                case .link(let url):
                    storage.addAttribute(.link, value: url, range: content)
                }
                // The markers around the content fade, so the words lead.
                if content != range {
                    let before = NSRange(location: range.location, length: content.location - range.location)
                    let after = NSRange(location: NSMaxRange(content), length: NSMaxRange(range) - NSMaxRange(content))
                    storage.addAttribute(.foregroundColor, value: markerColor, range: before)
                    storage.addAttribute(.foregroundColor, value: markerColor, range: after)
                }
            }
        }

        /// A paragraph that hangs its wrapped lines under the text after a
        /// marker `markerLength` long, so a list reads as a list.
        private static func hanging(_ markerLength: Int, line: String) -> NSParagraphStyle {
            let style = bodyParagraph.mutableCopy() as! NSMutableParagraphStyle
            let marker = (line as NSString).substring(to: min(markerLength, (line as NSString).length))
            let width = (marker as NSString).size(withAttributes: [.font: bodyFont]).width
            style.headIndent = width
            return style
        }
    }
#endif
