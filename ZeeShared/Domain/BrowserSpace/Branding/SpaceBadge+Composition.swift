import Foundation

/// A badge's composition as the Studio edits and the renderer draws it: the
/// colors and figure the layers use.
extension SpaceBadge {
    // MARK: - Static Variables

    /// The most colors a badge's own palette holds, as the core enforces it.
    static var maximumPaletteCount: Int { CapacityLimits.current.badgePalette }

    // MARK: - Variables

    /// The figure this badge draws: a custom charge when one was chosen, else
    /// the heraldic symbol.
    var resolvedCharge: BadgeCharge {
        charge ?? .heraldic(symbol)
    }

    /// Whether the badge draws with its own tinctures rather than the Space's.
    var usesOwnPalette: Bool { palette != nil }

    // MARK: - Actions - Colors

    /// The colors this badge's layer indices point into.
    func layerColors(spaceColors: ColorPalette) -> ColorPalette {
        if let palette, !palette.isEmpty { return palette }
        return spaceColors.isEmpty ? [.indigo] : spaceColors
    }
}

extension BadgeMeasure {
    /// The range the renderer draws the measure in.
    var range: ClosedRange<Double> { minimum...maximum }

    /// The range of a count, in whole pieces.
    var countRange: ClosedRange<Int> { Int(minimum)...Int(maximum) }
}
