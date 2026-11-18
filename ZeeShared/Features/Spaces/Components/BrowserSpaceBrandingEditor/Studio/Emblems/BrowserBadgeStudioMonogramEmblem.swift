import Foundation

/// An emblem of one or two letters in a chosen style.
struct BrowserBadgeStudioMonogramEmblem: BrowserBadgeStudioEmblemSource {
    // MARK: - Actions - Charge

    func charge(in emblem: BrowserBadgeStudioEmblem) -> BadgeCharge {
        .monogram(emblem.monogram, emblem.monogramStyle)
    }

    func load(_ charge: BadgeCharge, into emblem: BrowserBadgeStudioEmblem) {
        let text = charge.text ?? ""
        if emblem.monogram != text { emblem.monogram = text }
        emblem.monogramStyle = charge.style ?? .serif
    }
}
