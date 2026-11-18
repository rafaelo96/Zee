import Foundation

/// An emblem drawn from Zee's heraldic artwork, found by name.
struct BrowserBadgeStudioHeraldicEmblem: BrowserBadgeStudioEmblemSource {
    // MARK: - Actions - Charge

    func charge(in emblem: BrowserBadgeStudioEmblem) -> BadgeCharge {
        .heraldic(emblem.context.value.badge.symbol)
    }

    func load(_ charge: BadgeCharge, into emblem: BrowserBadgeStudioEmblem) {}
}
