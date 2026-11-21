import Foundation
import IOKit.ps

/// Tells the core whether the Mac saves power now: Low Power Mode is on, or
/// it runs on a battery at or below `lowBatteryLevel`. It reports as it starts
/// and whenever either changes, so Save Battery opens new pages in WebKit only
/// while it matters.
@MainActor
final class BrowserPowerConstraintMonitor {
    // MARK: - Static Variables

    /// The battery charge, out of 100, at or below which the Mac counts as
    /// running low.
    static let lowBatteryLevel = 20

    // MARK: - Variables

    private let core: ZeeCore
    private var powerStateObserver: NSObjectProtocol?
    private var powerSource: CFRunLoopSource?
    private var reported: Bool?

    // MARK: - Initializers

    init(core: ZeeCore) {
        self.core = core
    }

    // MARK: - Actions - Lifecycle

    func start() {
        guard powerStateObserver == nil else { return }
        powerStateObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.report() }
        }
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context else { return }
                let monitor = Unmanaged<BrowserPowerConstraintMonitor>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated { monitor.report() }
            }, context)?.takeRetainedValue()
        {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            powerSource = source
        }
        report()
    }

    func stop() {
        if let powerStateObserver { NotificationCenter.default.removeObserver(powerStateObserver) }
        powerStateObserver = nil
        if let powerSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), powerSource, .defaultMode) }
        powerSource = nil
    }

    // MARK: - Actions - Reporting

    private func report() {
        let constrained = ProcessInfo.processInfo.isLowPowerModeEnabled || Self.runsLowOnBattery()
        guard constrained != reported else { return }
        reported = constrained
        _ = try? core.send(ReportPowerConstraint(constrained: constrained))
    }

    /// Whether the Mac runs on a battery at or below `lowBatteryLevel`.
    private static func runsLowOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }
        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                description[kIOPSPowerSourceStateKey] as? String == kIOPSBatteryPowerValue,
                let current = description[kIOPSCurrentCapacityKey] as? Int,
                let maximum = description[kIOPSMaxCapacityKey] as? Int, maximum > 0
            else { continue }
            if current * 100 / maximum <= lowBatteryLevel { return true }
        }
        return false
    }
}
