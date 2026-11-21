import Foundation

/// The core's invitation to bring another browser's data, as a start page
/// offers it: the browser, when it stops working, and what bringing or
/// dismissing it does. Only a shell that can import supplies one.
struct BrowserStartPageInvitation {
    let source: ImportSource
    /// When the browser stops working, or nil for one that keeps working.
    let stopsWorkingAt: Date?
    let bring: @MainActor () -> Void
    let dismiss: @MainActor () -> Void
}
