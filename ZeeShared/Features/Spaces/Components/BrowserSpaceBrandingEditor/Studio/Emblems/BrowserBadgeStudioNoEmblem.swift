import Foundation

/// No emblem on the badge.
struct BrowserBadgeStudioNoEmblem: BrowserBadgeStudioEmblemSource {
    // MARK: - Actions - Charge

    func charge(in emblem: BrowserBadgeStudioEmblem) -> BadgeCharge {
        BadgeCharge.none
    }

    func load(_ charge: BadgeCharge, into emblem: BrowserBadgeStudioEmblem) {}
}
