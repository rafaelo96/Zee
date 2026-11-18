import Foundation

/// An emblem drawn from an SF Symbol.
struct BrowserBadgeStudioSystemEmblem: BrowserBadgeStudioEmblemSource {
    // MARK: - Actions - Charge

    func charge(in emblem: BrowserBadgeStudioEmblem) -> BadgeCharge {
        .system(emblem.systemName)
    }

    func load(_ charge: BadgeCharge, into emblem: BrowserBadgeStudioEmblem) {
        let text = charge.text ?? ""
        if emblem.systemName != text { emblem.systemName = text }
    }
}
