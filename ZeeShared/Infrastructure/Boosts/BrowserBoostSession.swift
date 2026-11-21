import Foundation

/// Applies the Boosts of one page: as its top document starts, it asks the
/// core which Boosts reach the page's Space and site, keeps their stylesheet
/// in the document and runs their scripts there once. When the person edits a
/// Boost, `refresh` restyles the document in place; a changed script runs from
/// the next document on.
@MainActor
final class BrowserBoostSession {
    // MARK: - Types

    typealias Evaluate =
        @MainActor (_ body: String, _ arguments: [String: Any], _ frame: BrowserContentFrame) async throws -> Any?

    // MARK: - Variables

    private let core: ZeeCore
    private let pageID: UUID
    private let evaluate: Evaluate
    /// The top document that last started, which the Boosts apply to.
    private var mainFrame: BrowserContentFrame?
    /// The site that document shows.
    private var host: String?

    // MARK: - Initializers

    init(core: ZeeCore, pageID: UUID, evaluate: @escaping Evaluate) {
        self.core = core
        self.pageID = pageID
        self.evaluate = evaluate
    }

    // MARK: - Actions - Messages

    /// Applies the Boosts to the top document that just started in `frame`.
    func receive(_ body: Any, from frame: BrowserContentFrame) {
        guard frame.isMainFrame, let message = body as? [String: Any],
            let url = (message["url"] as? String).flatMap(URL.init(string:)),
            ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else { return }
        mainFrame = frame
        host = url.host()
        apply(runningScripts: true)
    }

    /// Restyles the top document with the Boosts as they are now.
    func refresh() {
        apply(runningScripts: false)
    }

    // MARK: - Actions - Applying

    private func apply(runningScripts: Bool) {
        guard let frame = mainFrame, let page = core.state.pages[pageID] else { return }
        let boosts =
            (try? core.query(BoostsFor(workspaceID: page.workspaceID, spaceID: page.spaceID, host: host))) ?? []
        let sheet = boosts.map(\.stylesheet).joined(separator: "\n")
        let scripts = runningScripts ? boosts.map(\.script).filter { !$0.isEmpty } : []
        let evaluate = evaluate
        Task {
            _ = try? await evaluate(BrowserBoostContentBridge.applyBody, ["sheet": sheet], frame)
            for script in scripts {
                _ = try? await evaluate(script, [:], frame)
            }
        }
    }
}
