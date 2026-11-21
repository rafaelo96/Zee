import Foundation
import WebKit

// MARK: - Actions - WebKit

extension BrowserBoostContentBridge {
    static let contentWorld = WKContentWorld.world(name: "dev.zee.browser.boosts")

    /// Installs the bridge in the top document `userContentController` serves.
    static func install(
        in userContentController: WKUserContentController,
        receive: @escaping @MainActor (WKScriptMessage) -> Void
    ) -> BrowserScriptMessageProxy {
        let proxy = BrowserScriptMessageProxy(receive: receive)
        userContentController.add(proxy, contentWorld: contentWorld, name: messageHandlerName)
        userContentController.addUserScript(
            WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: contentWorld))
        return proxy
    }
}

/// WebKit delivers the Boost bridge through its own user content controller
/// and answers in the frame and content world that asked.
extension BrowserBoostSession {
    convenience init(webView: WKWebView, core: ZeeCore, pageID: UUID) {
        self.init(
            core: core, pageID: pageID,
            evaluate: { [weak webView] body, arguments, frame in
                guard let webView, let frameInfo = frame.handle as? WKFrameInfo else { return nil }
                return try await webView.callAsyncJavaScript(
                    body, arguments: arguments, in: frameInfo, contentWorld: BrowserBoostContentBridge.contentWorld)
            })
    }

    func receive(_ scriptMessage: WKScriptMessage) {
        guard scriptMessage.name == BrowserBoostContentBridge.messageHandlerName else { return }
        let origin = scriptMessage.frameInfo.securityOrigin
        receive(
            scriptMessage.body,
            from: BrowserContentFrame(
                isMainFrame: scriptMessage.frameInfo.isMainFrame, securityProtocol: origin.protocol, host: origin.host,
                port: origin.port, handle: scriptMessage.frameInfo))
    }
}
