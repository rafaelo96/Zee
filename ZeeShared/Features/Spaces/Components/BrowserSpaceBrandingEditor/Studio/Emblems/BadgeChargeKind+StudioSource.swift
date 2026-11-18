extension BadgeChargeKind {
    /// The source the badge studio edits this kind of emblem with.
    @MainActor
    var studioSource: any BrowserBadgeStudioEmblemSource {
        switch kind {
        case .heraldic: BrowserBadgeStudioHeraldicEmblem()
        case .system: BrowserBadgeStudioSystemEmblem()
        case .emoji: BrowserBadgeStudioEmojiEmblem()
        case .monogram: BrowserBadgeStudioMonogramEmblem()
        case .none: BrowserBadgeStudioNoEmblem()
        }
    }
}
