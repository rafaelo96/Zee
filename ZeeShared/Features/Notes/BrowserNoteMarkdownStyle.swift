import Foundation

/// What a note's Markdown means, line by line, independent of how a platform
/// draws it: headings, list items, checklist items and their state, emphasis
/// and links. A note keeps its text as Markdown, so it syncs and exports as
/// plain text and reads anywhere; the editor only styles what this finds.
enum BrowserNoteMarkdown {
    // MARK: - Types

    /// The role a line plays.
    enum Line: Equatable {
        case heading(level: Int, markerLength: Int)
        case bullet(markerLength: Int)
        case numbered(markerLength: Int)
        case checklist(isDone: Bool, markerLength: Int, boxRange: Range<Int>)
        case quote(markerLength: Int)
        case body
    }

    /// A span of inline styling, in UTF-16 offsets within its line.
    struct Inline: Equatable {
        enum Kind: Equatable {
            case bold
            case italic
            case code
            case link(URL)
        }

        let kind: Kind
        /// The whole span, markers included.
        let range: NSRange
        /// The text the markers wrap.
        let content: NSRange
    }

    // MARK: - Actions - Lines

    /// The role of `line`, which holds no line break.
    static func classify(_ line: String) -> Line {
        let text = line as NSString
        if let match = headingPattern.firstMatch(in: line, range: NSRange(location: 0, length: text.length)) {
            return .heading(level: match.range(at: 1).length, markerLength: match.range.length)
        }
        if let match = checklistPattern.firstMatch(in: line, range: NSRange(location: 0, length: text.length)) {
            let box = match.range(at: 2)
            let mark = text.substring(with: NSRange(location: box.location + 1, length: 1))
            return .checklist(
                isDone: mark.lowercased() == "x", markerLength: match.range.length,
                boxRange: box.location..<(box.location + box.length))
        }
        if let match = bulletPattern.firstMatch(in: line, range: NSRange(location: 0, length: text.length)) {
            return .bullet(markerLength: match.range.length)
        }
        if let match = numberedPattern.firstMatch(in: line, range: NSRange(location: 0, length: text.length)) {
            return .numbered(markerLength: match.range.length)
        }
        if let match = quotePattern.firstMatch(in: line, range: NSRange(location: 0, length: text.length)) {
            return .quote(markerLength: match.range.length)
        }
        return .body
    }

    /// The marker the line after a list item continues it with, or nil when
    /// `line` is no list item. A checklist continues unchecked, and a numbered
    /// list counts on.
    static func continuation(of line: String) -> String? {
        let text = line as NSString
        let whole = NSRange(location: 0, length: text.length)
        if let match = checklistPattern.firstMatch(in: line, range: whole) {
            return text.substring(with: match.range(at: 1)) + "[ ] "
        }
        if let match = bulletPattern.firstMatch(in: line, range: whole) {
            return text.substring(with: match.range)
        }
        if let match = numberedPattern.firstMatch(in: line, range: whole) {
            let indent = text.substring(with: match.range(at: 1))
            let number = Int(text.substring(with: match.range(at: 2))) ?? 0
            return "\(indent)\(number + 1). "
        }
        return nil
    }

    /// Whether `line` is only a list marker, which ends the list on Return.
    static func isEmptyListItem(_ line: String) -> Bool {
        guard let marker = continuation(of: line) else { return false }
        let bare = line.trimmingCharacters(in: .whitespaces)
        return bare.isEmpty || bare == marker.trimmingCharacters(in: .whitespaces)
            || line.count <= markerLength(of: line)
    }

    /// How long `line`'s list or heading marker is, or 0.
    static func markerLength(of line: String) -> Int {
        switch classify(line) {
        case .heading(_, let length), .bullet(let length), .numbered(let length), .quote(let length): length
        case .checklist(_, let length, _): length
        case .body: 0
        }
    }

    // MARK: - Actions - Inline

    /// The emphasis, code and links `line` holds, links first so emphasis in
    /// a link's address is never read as emphasis.
    static func inlines(in line: String) -> [Inline] {
        let whole = NSRange(location: 0, length: (line as NSString).length)
        var spans: [Inline] = []
        for match in linkPattern.matches(in: line, range: whole) {
            let address = (line as NSString).substring(with: match.range(at: 2))
            guard let url = URL(string: address), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { continue }
            spans.append(Inline(kind: .link(url), range: match.range, content: match.range(at: 1)))
        }
        if let detector = linkDetector {
            for match in detector.matches(in: line, range: whole) {
                guard let url = match.url, ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                    !spans.contains(where: { NSIntersectionRange($0.range, match.range).length > 0 })
                else { continue }
                spans.append(Inline(kind: .link(url), range: match.range, content: match.range))
            }
        }
        func add(_ pattern: NSRegularExpression, _ kind: Inline.Kind) {
            for match in pattern.matches(in: line, range: whole)
            where !spans.contains(where: { NSIntersectionRange($0.range, match.range).length > 0 }) {
                spans.append(Inline(kind: kind, range: match.range, content: match.range(at: 1)))
            }
        }
        add(codePattern, .code)
        add(boldPattern, .bold)
        add(italicPattern, .italic)
        return spans
    }

    // MARK: - Patterns

    private static let headingPattern = regex(#"^(#{1,3}) +"#)
    private static let checklistPattern = regex(#"^(\s*[-*] )(\[[ xX]\]) "#)
    private static let bulletPattern = regex(#"^\s*[-*•] "#)
    private static let numberedPattern = regex(#"^(\s*)(\d{1,4})[.)] "#)
    private static let quotePattern = regex(#"^> ?"#)
    private static let linkPattern = regex(#"\[([^\]\n]+)\]\(([^)\s]+)\)"#)
    private static let codePattern = regex(#"`([^`\n]+)`"#)
    private static let boldPattern = regex(#"\*\*([^*\n]+)\*\*"#)
    private static let italicPattern = regex(#"(?<![*\w])[*_]([^*_\n]+)[*_](?![*\w])"#)
    private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are literals this file owns, so they always compile.
        try! NSRegularExpression(pattern: pattern)
    }
}
