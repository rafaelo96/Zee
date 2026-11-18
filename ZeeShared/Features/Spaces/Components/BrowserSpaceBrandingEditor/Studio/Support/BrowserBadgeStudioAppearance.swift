import Foundation

/// Artwork resources and explicit shuffle actions shared by every studio presentation.
enum BrowserBadgeStudioAppearance {
    static func shuffle(_ branding: SpaceBranding) -> SpaceBranding {
        var value = branding
        value.iconStyle = .layeredBadge
        value.badge.backplate = [.shield, .frenchShield, .circle, .hexagon, .banner].randomElement() ?? .shield
        value.badge.fieldDivision = [.plain, .perPale, .perBend, .quarterly].randomElement() ?? .plain
        value.badge.ordinary =
            value.badge.fieldDivision == .plain ? [.none, .chevron, .fess, .pale].randomElement() ?? .none : .none
        value.badge.symbol = BadgeSymbol.selectable.randomElement() ?? .dragon
        value.badge.charge = nil
        value.badge.chargeLayout = .single
        value.badge.chargeScale = 1.15
        value.badge.chargeOffset = 0
        value.badge.plateScale = 1
        value.badge.trim = [.none, .line, .doubleLine].randomElement() ?? .none
        value.badge.trimWeight = 0.75
        value.badge.edgeWidth = 0
        value.badge.finish = .flat
        value.badge.backplateColorIndex = 0
        value.badge.secondaryFieldColorIndex = min(1, value.badge.layerColors(spaceColors: value.colors).count - 1)
        value.badge.symbolColorIndex = value.badge.layerColors(spaceColors: value.colors).count - 1
        value.badge.trimColorIndex = value.badge.symbolColorIndex
        value.hasCustomAppearance = true
        return value.normalized()
    }

    static let credits: String = {
        guard let url = Bundle.main.url(forResource: "HeraldicArtworkCredits", withExtension: "txt"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else { return "Game-icons.net · CC BY 3.0" }
        return text
    }()
}
