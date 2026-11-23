import Foundation

/// How what a page gives a note is written in the note's Markdown: the page
/// a clip came from, named and linked, and a link on its own.
@MainActor
enum BrowserNoteClip {
    /// The line under a clip that names and links the page it came from.
    static func source(of page: BrowserPage, title: String) -> String {
        guard let url = page.live.displayURL else { return "— " + title }
        return "— " + link(url, title: title)
    }

    /// `url` as a Markdown link titled `title`, or by its host.
    static func link(_ url: URL, title: String? = nil) -> String {
        let name = (title?.isEmpty == false ? title : nil) ?? url.host() ?? url.absoluteString
        let label = name.replacingOccurrences(of: "[", with: "(").replacingOccurrences(of: "]", with: ")")
        return "[\(label)](\(url.absoluteString))"
    }
}

/// Where a region the person draws over a page goes.
enum BrowserRegionCaptureDestination: Equatable {
    case clipboard
    case note
}
