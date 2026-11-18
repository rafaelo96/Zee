import XCTest

@testable import ZeeMobile

/// The share extension hands links to the app through a URL any app can
/// open, so these protect what that hand-off carries and accepts.
final class BrowserSharedLinkTests: XCTestCase {
    func testHandOffAcceptsOnlyAWebLinkThroughZeeOpen() throws {
        let rejected = [
            "https://example.com",
            "zee://other?url=https%3A%2F%2Fexample.com",
            "zee://open/path?url=https%3A%2F%2Fexample.com",
            "zee://open",
            "zee://open?url=",
            "zee://open?url=javascript%3Aalert(1)",
            "zee://open?url=file%3A%2F%2F%2Fetc%2Fpasswd",
            "zee://open?url=data%3Atext%2Fhtml%2Chi",
            "zee://open?url=https%3A%2F%2F",
            "zee://open?url=zee%3A%2F%2Fopen%3Furl%3Dhttps%253A%252F%252Fexample.com",
            "zee://open?url=https%3A%2F%2Fa.com&url=https%3A%2F%2Fb.com",
        ]
        for string in rejected {
            let url = try XCTUnwrap(URL(string: string), string)
            XCTAssertNil(BrowserSharedLink(handOffURL: url), string)
        }

        let accepted = try XCTUnwrap(URL(string: "ZEE://open?url=http%3A%2F%2Fexample.com&later=1"))
        XCTAssertEqual(BrowserSharedLink(handOffURL: accepted)?.url.absoluteString, "http://example.com")
    }
}
