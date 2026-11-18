import Foundation

/// The product's name and identifiers, read from the built bundle so that
/// `Config/Zee.xcconfig` is the only place to change them.
enum ProductIdentity {
    /// Used when the bundle gives nothing, such as in unit-test hosts.
    private static let fallbackName = "Zee"
    private static let fallbackBundleIdentifier = "dev.zee.browser"

    static let name: String = {
        let info = Bundle.main.infoDictionary ?? [:]
        let value = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
        guard let value, !value.isEmpty, !value.hasPrefix("$(") else { return fallbackName }
        return value
    }()

    static let bundleIdentifier: String = {
        guard let value = Bundle.main.bundleIdentifier, !value.isEmpty, !value.hasPrefix("$(") else {
            return fallbackBundleIdentifier
        }
        return value
    }()

    static let serviceNamespace = bundleIdentifier
    static let storageDirectoryName = name

    /// Base URL of this product's own Sparkle feed. Nil keeps update checks off,
    /// so a fork never installs an upstream release over itself.
    static let updateFeedBaseURL: URL? = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ZeeUpdateFeedBaseURL") as? String,
            !value.isEmpty, !value.hasPrefix("$("), let url = URL(string: value)
        else { return nil }
        return url
    }()
}
