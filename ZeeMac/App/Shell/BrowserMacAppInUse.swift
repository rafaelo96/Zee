import AppKit

/// Which app the person is using as they switch between apps, so what
/// another app hands Zee, or the Quick Window keys pressed there, opens
/// over the app they are in, while what reaches Zee as they use it stays in
/// Zee.
@MainActor
final class BrowserMacAppInUse {
    // MARK: - Static Variables

    /// How long after coming forward Zee counts as brought forward by what
    /// arrives: LaunchServices brings Zee forward just before it hands over
    /// a link another app opened.
    private static let broughtForwardSpan: Duration = .seconds(1)

    // MARK: - Variables

    /// The app the person was in last outside Zee: the last one with
    /// windows of its own to come forward, or at launch, the one in front.
    private var lastOtherApp: BrowserQuickWindowSourceApp?
    /// When Zee last came forward, while it is in front.
    private var zeeCameForward: ContinuousClock.Instant?
    private var observers: [any NSObjectProtocol] = []

    // MARK: - Initializers

    /// Starts following the apps the person switches to, from the one they
    /// are in as Zee launches. A launch brings Zee forward before it has
    /// a window, so that app is the one whose window is in front.
    init() {
        lastOtherApp =
            BrowserQuickWindowSourceApp(NSWorkspace.shared.frontmostApplication)
            ?? BrowserQuickWindowSourceApp.showingFrontWindow()
        let appActivated: @Sendable (Notification) -> Void = { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let processID = app?.processIdentifier
            MainActor.assumeIsolated { self?.appCameForward(processID) }
        }
        let zeeActivated: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.zeeCameForward = .now }
        }
        let zeeDeactivated: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.zeeCameForward = nil }
        }
        observers = [
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main,
                using: appActivated),
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main,
                using: zeeActivated),
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification, object: nil, queue: .main, using: zeeDeactivated),
        ]
    }

    // MARK: - Actions - Apps

    /// The app the person is in outside Zee, which what reaches Zee now
    /// came from, or nil when it came from Zee: Zee handed itself a link
    /// it opened through the system as the default browser, or the person is
    /// using Zee. Zee that came forward a moment ago, or is coming forward
    /// as it launches, came forward for what arrives.
    func appOutsideZee() -> BrowserQuickWindowSourceApp? {
        guard !isFromZee else { return nil }
        if NSApp.isActive, let zeeCameForward, ContinuousClock.now - zeeCameForward > Self.broughtForwardSpan {
            return nil
        }
        return runningLastOtherApp
    }

    /// The app the person pressed keys in, such as the Quick Window keys, or
    /// nil while Zee is in front. Keys pressed in another app never bring
    /// Zee forward first, so Zee in front means they were pressed in
    /// Zee, however recently it came forward.
    func appPressedIn() -> BrowserQuickWindowSourceApp? {
        NSApp.isActive ? nil : runningLastOtherApp
    }

    /// The app the person was in last outside Zee, while it still runs.
    private var runningLastOtherApp: BrowserQuickWindowSourceApp? {
        lastOtherApp?.isRunning == true ? lastOtherApp : nil
    }

    /// Whether the Apple Event Zee is handling, such as the one that hands
    /// it a link, is Zee's own.
    private var isFromZee: Bool {
        let sender = NSAppleEventManager.shared().currentAppleEvent?
            .attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value
        return sender == ProcessInfo.processInfo.processIdentifier
    }

    private func appCameForward(_ processID: pid_t?) {
        guard let app = BrowserQuickWindowSourceApp(processID.flatMap { NSRunningApplication(processIdentifier: $0) })
        else { return }
        lastOtherApp = app
    }
}
