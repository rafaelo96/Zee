import Foundation

extension NotificationPermissionRequest {
    // MARK: - Variables

    /// What a notification permission request leads to. An unavailable core
    /// denies it.
    var action: HostedNotificationRequestAction {
        (try? ZeeCore.answer(self))?.action ?? .respondDenied
    }
}
