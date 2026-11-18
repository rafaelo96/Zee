import Foundation

enum BrowserAddressFocusDismissal {
    static let notification = Notification.Name(
        "dev.zee.browser.dismiss-address-focus"
    )

    static func dismiss() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}
