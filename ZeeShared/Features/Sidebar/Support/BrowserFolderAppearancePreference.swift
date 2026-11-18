import Foundation

/// Global interface choices use the same defaults domain as the rest of the app.
/// Space color strength travels separately with the existing branding payload.
@MainActor
enum BrowserFolderAppearancePreference {
    static let alwaysVisibleKey = "zee.folders.alwaysShowHighlights"
    static let showsTabCountsKey = "zee.folders.showsTabCounts"
    static let showsBordersKey = "zee.folders.showsBorders"
    static let iconOnlyKey = "zee.folders.iconOnly"
    static let tintsTitleKey = "zee.folders.tintsTitle"
    static let groupsAlwaysVisibleKey = "zee.groups.alwaysShowHighlights"
    static let groupsShowsTabCountsKey = "zee.groups.showsTabCounts"
    static let groupsShowsBordersKey = "zee.groups.showsBorders"
    static let groupsTintsTitleKey = "zee.groups.tintsTitle"

    static let defaults: UserDefaults = {
        let environment = BrowserLaunchEnvironment.current
        guard environment.requiresIsolation else { return .standard }
        let id = environment.persistentIsolationID ?? "ephemeral-\(UUID().uuidString)"
        return UserDefaults(suiteName: BrowserLaunchEnvironment.isolatedDefaultsSuiteName(isolationID: id))!
    }()
}
