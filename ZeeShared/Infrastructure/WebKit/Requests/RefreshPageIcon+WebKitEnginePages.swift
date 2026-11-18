import Foundation

extension RefreshPageIcon {
    /// Zee fetches its WebKit pages' icons itself.
    @MainActor func answer(on pages: WebKitEnginePages) -> Answer {
        false
    }
}
