import Foundation

/// Zee's address namespace is separate from Chromium's privileged origins:
/// an engine page's address reaches Zee in its own `zee://` spelling,
/// leaving web and extension URLs intact. The binding translates the other
/// way itself.
enum ChromiumInternalURL {
    static func presented(_ value: String) -> String {
        replacingScheme(in: value, from: "chrome", to: "zee")
    }

    private static func replacingScheme(in value: String, from: String, to: String) -> String {
        let prefix = from + "://"
        guard value.prefix(prefix.count).lowercased() == prefix else { return value }
        // Preserve escaped paths, query strings and fragments byte for byte.
        return to + "://" + value.dropFirst(prefix.count)
    }
}
