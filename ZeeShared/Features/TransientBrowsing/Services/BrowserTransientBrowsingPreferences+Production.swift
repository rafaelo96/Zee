extension BrowserTransientBrowsingPreferences {
    /// The app's preferences, as `core` holds this device's link preferences.
    static func production(core: ZeeCore) -> BrowserTransientBrowsingPreferences {
        BrowserTransientBrowsingPreferences(
            archiveLifetime: { [weak core] in core?.state.linkPreferences?.archivePolicy.lifetime },
            rememberSpace: { [weak core] spaceID, url in
                _ = try? core?.send(RememberQuickWindowSpace(url: url.absoluteString, spaceID: spaceID))
            }
        )
    }
}
