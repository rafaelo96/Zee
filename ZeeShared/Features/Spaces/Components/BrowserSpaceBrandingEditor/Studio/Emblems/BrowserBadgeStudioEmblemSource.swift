import Foundation

/// One source of a badge's emblem in the studio: the charge its fields make,
/// and what it takes back from a charge. `BadgeChargeKind.studioSource` names
/// each kind's source, so a kind the core adds fails to compile until the
/// studio offers a source for it. The controls that edit a source are views
/// ``BrowserBadgeStudioEmblem`` chooses by the kind.
@MainActor
protocol BrowserBadgeStudioEmblemSource {
    /// The charge the emblem's fields make for this source.
    func charge(in emblem: BrowserBadgeStudioEmblem) -> BadgeCharge

    /// Takes the fields this source edits from `charge`.
    func load(_ charge: BadgeCharge, into emblem: BrowserBadgeStudioEmblem)
}
