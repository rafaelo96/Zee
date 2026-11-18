import CloudKit
import Foundation
import XCTest

@testable import Zee

final class BrowserCloudSyncStateTests: XCTestCase {
    /// Zee rebuilds a zone iCloud lost only when this device holds the
    /// surviving copy; a deletion or a purge is somebody's decision.
    func testRemovingZeesICloudDataIsNotImmediatelyUndone() {
        XCTAssertFalse(BrowserCloudSyncEngine.loss(afterZoneDeletion: .purged).restoresLocalRecords)
        XCTAssertFalse(BrowserCloudSyncEngine.loss(afterZoneDeletion: .deleted).restoresLocalRecords)
        XCTAssertTrue(BrowserCloudSyncEngine.loss(afterZoneDeletion: .encryptedDataReset).restoresLocalRecords)
    }
}
