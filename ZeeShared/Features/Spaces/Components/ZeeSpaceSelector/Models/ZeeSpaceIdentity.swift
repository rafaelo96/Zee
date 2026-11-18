import SwiftUI

/// The identity a space-picking control needs: who the Space is, what it is called
/// right now, and which colour it owns.
///
/// It carries the Space's whole identity because the badge is rendered from its
/// branding — flattening it to an id and a name would mean re-deriving the badge at
/// every call site. `displayName` exists for drafts whose name is still being typed
/// and for menus that want a phrase rather than a bare name.
struct ZeeSpaceIdentity: Identifiable, Equatable {
    let space: BrowserSpaceIdentity
    var displayName: String?
    var tintOverride: Color?

    var id: UUID { space.id }
    var name: String { displayName ?? space.name }
    var tint: Color { tintOverride ?? space.accent.tint.color }

    @MainActor
    init(space: some BrowserSpaceIdentifying, displayName: String? = nil, tint: Color? = nil) {
        self.space = space.identity
        self.displayName = displayName
        tintOverride = tint
    }

    /// Spaces of the read model, or values no session holds yet, such as
    /// drafts and previews.
    @MainActor
    static func list(_ spaces: [some BrowserSpaceIdentifying]) -> [ZeeSpaceIdentity] {
        spaces.map { ZeeSpaceIdentity(space: $0) }
    }
}
