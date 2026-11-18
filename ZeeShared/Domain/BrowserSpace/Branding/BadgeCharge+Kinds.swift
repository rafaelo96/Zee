import Foundation

/// What a badge bears: a figure from the heraldic set, any system symbol, an
/// emoji, a monogram of up to two letters, or nothing.
extension BadgeCharge {
    // MARK: - Static Variables

    /// A charge that draws nothing in place of the heraldic figure.
    static let none = BadgeCharge(kind: .none, symbol: nil, text: nil, style: nil)

    // MARK: - Initializers

    static func heraldic(_ symbol: BadgeSymbol) -> BadgeCharge {
        BadgeCharge(kind: .heraldic, symbol: symbol, text: nil, style: nil)
    }

    static func system(_ name: String) -> BadgeCharge {
        BadgeCharge(kind: .system, symbol: nil, text: name, style: nil)
    }

    static func emoji(_ emoji: String) -> BadgeCharge {
        BadgeCharge(kind: .emoji, symbol: nil, text: emoji, style: nil)
    }

    static func monogram(_ letters: String, _ style: BadgeMonogramStyle) -> BadgeCharge {
        BadgeCharge(kind: .monogram, symbol: nil, text: letters, style: style)
    }
}
