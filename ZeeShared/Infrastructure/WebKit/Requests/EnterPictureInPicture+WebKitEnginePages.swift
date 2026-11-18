import Foundation

extension EnterPictureInPicture {
    /// Zee runs its WebKit pages' Picture in Picture through its own bridge in the page.
    @MainActor func answer(on pages: WebKitEnginePages) -> Answer {
        false
    }
}
