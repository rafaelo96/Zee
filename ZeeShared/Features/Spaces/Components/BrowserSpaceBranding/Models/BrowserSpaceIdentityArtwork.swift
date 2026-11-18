enum BrowserSpaceIdentityArtwork: Equatable {
    case badge
    case symbol(String)

    init(_ identity: BrowserSpaceIdentity) {
        self =
            identity.branding.iconStyle == .layeredBadge
            ? .badge
            : .symbol(identity.symbol)
    }
}
