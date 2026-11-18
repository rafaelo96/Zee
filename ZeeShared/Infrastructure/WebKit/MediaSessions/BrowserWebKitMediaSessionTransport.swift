import Foundation
import WebKit

/// WebKit runs Zee's Media Session bridge in the page's own world and
/// addresses it by the document identifier the coordinator issued.
@MainActor
final class BrowserWebKitMediaSessionTransport: BrowserMediaSessionTransport {
    private(set) weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    var mediaSessionLocation: String? { webView?.url?.absoluteString }

    func activateMediaSession(documentIdentifier: String) {
        call(
            "return globalThis.__zeeMediaSessionBridge?.activate(documentIdentifier);",
            ["documentIdentifier": documentIdentifier]
        )
    }

    func performMediaSessionAction(_ action: MediaSessionAction, documentIdentifier: String) {
        call(
            """
            return globalThis.__zeeMediaSessionBridge?.perform(
              action,
              documentIdentifier
            ) === true;
            """,
            ["action": action.pageName, "documentIdentifier": documentIdentifier]
        )
    }

    func setMediaSessionMuted(_ muted: Bool, documentIdentifier: String) {
        call(
            """
            return globalThis.__zeeMediaSessionBridge?.setMuted(
              muted,
              documentIdentifier
            ) === true;
            """,
            ["muted": muted, "documentIdentifier": documentIdentifier]
        )
    }

    private func call(_ body: String, _ arguments: [String: Any]) {
        Task { @MainActor [weak webView] in
            _ = try? await webView?.callAsyncJavaScript(
                body,
                arguments: arguments,
                in: nil,
                contentWorld: BrowserMediaSessionContentBridge.contentWorld
            )
        }
    }
}
