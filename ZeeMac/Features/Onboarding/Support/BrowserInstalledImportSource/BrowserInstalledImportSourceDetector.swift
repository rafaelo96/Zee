import AppKit

@MainActor
enum BrowserInstalledImportSourceDetector {
    /// Each browser Zee imports from that is installed, found by its app,
    /// and each whose data outlives its app, found by that file being there.
    /// Reading another app's data can make macOS warn that Zee looked at it,
    /// so setup reads none until the person asks.
    static func installedSources(
        workspace: NSWorkspace = .shared
    ) -> [BrowserInstalledImportSource] {
        ImportSource.all.compactMap { application in
            if let url = workspace.urlForApplication(withBundleIdentifier: application.bundleIdentifier) {
                let icon = workspace.icon(forFile: url.path)
                icon.size = NSSize(width: 64, height: 64)
                return BrowserInstalledImportSource(application: application, applicationURL: url, icon: icon)
            }
            return leftBehind(application)
        }
    }

    /// `application` without its app, when the file its data outlives the
    /// app by is still in its data folder, under the browser's own symbol.
    private static func leftBehind(_ application: ImportSource) -> BrowserInstalledImportSource? {
        let folder = application.defaultDataDirectory
        guard let file = application.outlivingFile,
            FileManager.default.fileExists(atPath: folder.appendingPathComponent(file).path),
            let icon = NSImage(systemSymbolName: application.symbol, accessibilityDescription: application.title)
        else { return nil }
        icon.size = NSSize(width: 64, height: 64)
        return BrowserInstalledImportSource(application: application, applicationURL: folder, icon: icon)
    }

    /// `source` with what the core finds in its data folder.
    static func scanned(_ source: BrowserInstalledImportSource) -> BrowserInstalledImportSource {
        let application = source.application
        return source.detecting(
            BrowserDetectedImportPayload(
                application: application, data: application.importData(in: application.defaultDataDirectory)))
    }

    /// The browsers installed here that Zee does not list, each paired by
    /// the core with the Chromium data it keeps, under the browser's own name
    /// and icon. Every app that opens web links is a candidate; Zee itself
    /// and the browsers it lists are not.
    static func unlistedSources(
        workspace: NSWorkspace = .shared
    ) -> [BrowserInstalledImportSource] {
        guard let link = URL(string: "https://example.com") else { return [] }
        let listed = Set(ImportSource.all.map(\.bundleIdentifier))
        var urls: [String: URL] = [:]
        let apps = workspace.urlsForApplications(toOpen: link).compactMap { url -> ImportBrowserApp? in
            guard let identifier = Bundle(url: url)?.bundleIdentifier,
                !listed.contains(identifier), !identifier.hasPrefix(ProductIdentity.bundleIdentifier),
                urls[identifier] == nil
            else { return nil }
            urls[identifier] = url
            return ImportBrowserApp(
                bundleIdentifier: identifier,
                name: FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: ""))
        }
        guard !apps.isEmpty,
            let found = try? ZeeCore.answer(
                FindChromiumBrowsers(home: ImportSource.hostHomeDirectory.path, apps: apps))
        else { return [] }
        return found.compactMap { browser in
            guard let url = urls[browser.bundleIdentifier] else { return nil }
            let icon = workspace.icon(forFile: url.path)
            icon.size = NSSize(width: 64, height: 64)
            return BrowserInstalledImportSource(
                application: .otherChromium,
                applicationURL: url,
                detectedPayload: BrowserDetectedImportPayload(application: .otherChromium, data: browser.data),
                icon: icon,
                title: browser.name
            )
        }
    }
}
