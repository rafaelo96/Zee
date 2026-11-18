import Foundation

/// An emblem drawn from an emoji.
struct BrowserBadgeStudioEmojiEmblem: BrowserBadgeStudioEmblemSource {
    // MARK: - Actions - Charge

    func charge(in emblem: BrowserBadgeStudioEmblem) -> BadgeCharge {
        .emoji(emblem.emoji)
    }

    func load(_ charge: BadgeCharge, into emblem: BrowserBadgeStudioEmblem) {
        let text = charge.text ?? ""
        if emblem.emoji != text { emblem.emoji = text }
    }
}
