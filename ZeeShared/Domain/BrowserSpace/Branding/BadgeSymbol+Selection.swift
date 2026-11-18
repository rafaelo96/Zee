import Foundation

extension BadgeSymbol {
    // MARK: - Static Variables

    /// The figure a badge draws when it names none it can read, as the core
    /// reads it.
    static let fallback = BadgeSymbol.mountain

    /// The figures the gallery offers.
    static let selectable: [BadgeSymbol] = all.filter(\.isOffered)
}
