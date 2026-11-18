import Foundation

enum BrowserTabPromotionID {
    static func value(for tabID: UUID) -> String {
        "zee-tab-promotion-\(tabID)"
    }
}
