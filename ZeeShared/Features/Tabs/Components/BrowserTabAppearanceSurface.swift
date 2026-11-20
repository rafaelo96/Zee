import SwiftUI

/// Appearance only; selection, promotion and drag owners remain on the row.
struct BrowserTabAppearanceSurface: ViewModifier {
    let appearance: BrowserTabAppearance
    let accent: Color
    let isPinned: Bool
    let isSelected: Bool
    let isHovering: Bool
    var selectionEmphasis = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.sidebarLayerDepth) private var depth
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let radius = BrowserSidebarMetrics.layerCornerRadius(depth: depth)
        let selectedAccent = isPinned || appearance.outlinesSelectedTabs
        let showsBorder = appearance.borders == .all || (isPinned && appearance.borders == .pinned)
        // Each choice is read only where it shows, so a drag of the pin fill
        // or the hover tint re-renders the pins or the hovered row alone.
        let fill = isPinned ? BrowserTabAppearance.intensity(appearance.pinFill) : 0
        let hover = isHovering ? BrowserTabAppearance.intensity(appearance.hoverFill) : 0
        content
            .modifier(
                ZeeInteractiveSurfaceModifier(
                    isSelected: isSelected, selectionEmphasis: selectionEmphasis,
                    isHovering: isHovering, cornerRadius: radius, isPressed: false,
                    showsRestingSurface: isPinned,
                    selectedBorderColor: selectedAccent ? accent : selectedBorder,
                    selectedBorderWidth: isPinned
                        ? ZeeLayout.pinnedAccentBorderWidth : ZeeInteractiveSurfaceMetrics.defaultSelectedBorderWidth,
                    customSelectedFill: isPinned
                        ? (fill > 0 && !reduceTransparency ? accent.opacity(fill * 0.5) : nil) : selectionLift,
                    // Hover keeps its standard weight; the setting only decides how much of
                    // the accent is in it, from the neutral hover to the accent itself.
                    customHoverFill: hover > 0 && !reduceTransparency
                        ? Color.primary.mix(with: accent, by: hover).opacity(ZeeOpacity.hover) : nil,
                    customRestingFill: isPinned && fill > 0 && !reduceTransparency ? accent.opacity(fill * 0.2) : nil,
                    restingBorderColor: showsBorder ? accent : .clear)
            )
            .background {
                if isSelected, appearance.pinGlow > 0, !reduceTransparency {
                    BrowserTabSelectionGlow(
                        cornerRadius: radius,
                        color: accent.opacity(BrowserTabAppearance.intensity(appearance.pinGlow) * 0.6)
                    )
                }
            }
    }

    /// The lift a selected row takes, so it reads as a pane floating above
    /// the sidebar, as Arc's does: brighter than the sidebar, never darker.
    /// Light glass turns nearly white; dark glass lifts a step.
    private var selectionLift: Color? {
        colorScheme == .dark
            ? Color.white.opacity(ZeeOpacity.darkSelectionLift)
            : Color.white.opacity(ZeeOpacity.lightSelectionLift)
    }

    /// A selected row's edge: brighter over dark glass, where the standard
    /// hairline disappears into a dark sidebar.
    private var selectedBorder: Color {
        guard !isPinned else { return ZeeColor.selectedBorder }
        return colorScheme == .dark
            ? Color.white.opacity(ZeeOpacity.darkSelectionBorder) : Color.black.opacity(ZeeOpacity.lightSelectionBorder)
    }
}
