import Foundation
import XCTest

@testable import Zee

final class BrowserDownloadDestinationTests: XCTestCase {
    func testRemovesWindowsTraversalControlCharactersAndHiddenEdges() {
        XCTAssertEqual(
            BrowserDownloadDestination.safeFilename(from: "..\\..\\.pay\u{0}load.txt. "),
            "payload.txt"
        )
        XCTAssertEqual(BrowserDownloadDestination.safeFilename(from: "../.."), "download")
    }

}
