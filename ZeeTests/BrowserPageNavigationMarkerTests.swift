import WebKit
import XCTest

@testable import Zee

@MainActor
final class BrowserPageNavigationMarkerTests: XCTestCase {
    /// The pool of the page a test drives, which keeps its window and
    /// workspace open: a workspace that closes takes its pages with it.
    private var pool: BrowserPagePool?

    func testTheAppInitiatedMarkerIsConsumedByTheNavigationItAuthorized() throws {
        let page = try makePage()
        let fileURL = URL(fileURLWithPath: "/tmp/zee-desktop-fixture.html")
        let replay = ReplayNavigationAction(url: fileURL)

        page.load(fileURL)
        XCTAssertTrue(
            page.isAppInitiated(replay),
            "The load Zee just asked for is app-initiated until WebKit honors it."
        )

        page.webView(page.webView, didStartProvisionalNavigation: nil)

        XCTAssertFalse(
            page.isAppInitiated(replay),
            "Web content must not be able to replay a file URL Zee once loaded."
        )
        XCTAssertEqual(
            SchemeHandling.disposition(
                for: fileURL,
                isAppInitiated: page.isAppInitiated(replay)
            ),
            .blocked
        )
    }

    private func makePage() throws -> BrowserPage {
        let tab = TabState.Seed.startPage()
        let space = SpaceState.Seed(
            name: "Marker",
            symbol: "circle",
            accent: .indigo,
            folders: [],
            tabs: [tab]
        )
        let pool = BrowserPagePool(browser: .hostingPages(SessionState.Seed(spaces: [space])))
        self.pool = pool
        pool.present(tab: tab.id, in: space.id)
        return try XCTUnwrap(pool.activePage)
    }

}

/// Stands in for a navigation web content asks for while naming a URL Zee once
/// loaded itself. WebKit never lets an app build a real `WKNavigationAction`, and
/// the web source origin is what separates a replay from Zee's own load.
private final class ReplayNavigationAction: WKNavigationAction,
    BrowserNavigationActionSourceOriginProviding
{
    private let stubRequest: URLRequest

    init(url: URL) {
        stubRequest = URLRequest(url: url)
        super.init()
    }

    override var request: URLRequest { stubRequest }
    override var navigationType: WKNavigationType { .other }
    override var targetFrame: WKFrameInfo? { nil }
    var browserSourceOrigin: SiteOrigin? {
        SiteOrigin(scheme: "https", host: "replay.zee.test", port: 443)
    }
}
